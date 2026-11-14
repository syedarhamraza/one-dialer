package com.syedarhamraza.recorder

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.audiofx.AutomaticGainControl
import java.io.File

/**
 * mic (AudioRecord) → [Compressor] → AAC (MediaCodec) → .m4a (MediaMuxer), on its own thread.
 * With several [sources] it spends about a second on each, keeps the loudest (reported through
 * [onSourceChosen]) and records on with it; the audio stays one continuous file throughout.
 */
class AudioPipeline(
    private val file: File,
    private val sources: List<Int>,
    boost: Compressor.Level,
    private val onSourceChosen: (Int) -> Unit,
    private val onSilent: () -> Unit,
) {
    private val compressor = Compressor(boost, RATE)
    @Volatile private var running = false
    private var thread: Thread? = null
    private var record: AudioRecord? = null
    private var gain: AutomaticGainControl? = null

    /** Opens the first source that works; false when none does (the caller falls back to MediaRecorder). */
    fun start(): Boolean {
        val first = sources.firstNotNullOfOrNull { s -> open(s)?.let { s to it } } ?: return false
        record = first.second
        running = true
        thread = Thread({ loop(first.first) }, "recorder").apply { start() }
        return true
    }

    /** Finishes the file; blocks until the encoder has written its last frame. */
    fun stop() {
        running = false
        thread?.join(3000)
        thread = null
    }

    @SuppressLint("MissingPermission") // RecordingService checks RECORD_AUDIO before starting
    private fun open(source: Int): AudioRecord? {
        val min = AudioRecord.getMinBufferSize(RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        if (min <= 0) return null
        val r = try {
            AudioRecord(source, RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, maxOf(min, CHUNK * 2) * 2)
        } catch (_: Exception) {
            return null
        }
        if (r.state != AudioRecord.STATE_INITIALIZED) return r.release().let { null }
        try {
            r.startRecording()
        } catch (_: Exception) {
            return r.release().let { null }
        }
        if (r.recordingState != AudioRecord.RECORDSTATE_RECORDING) return r.release().let { null }
        gain?.release()
        gain = if (AutomaticGainControl.isAvailable()) AutomaticGainControl.create(r.audioSessionId)?.apply { enabled = true } else null
        return r
    }

    private fun switchTo(source: Int): Boolean {
        val next = open(source) ?: return false
        record?.run { stop(); release() }
        record = next
        return true
    }

    private fun loop(firstSource: Int) {
        // An encoder or file that won't open must not take the process down (an uncaught exception
        // on this thread would) with the microphone still held.
        var codec: MediaCodec? = null
        var muxer: MediaMuxer? = null
        val writer = try {
            codec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
            codec.configure(
                MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_AAC, RATE, 1).apply {
                    setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
                    setInteger(MediaFormat.KEY_BIT_RATE, 64_000)
                    setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, CHUNK * 2)
                },
                null, null, MediaCodec.CONFIGURE_FLAG_ENCODE,
            )
            codec.start()
            muxer = MediaMuxer(file.path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            Writer(codec, muxer)
        } catch (_: Exception) {
            gain?.release()
            record?.run { runCatching { stop() }; release() }
            record = null
            codec?.release()
            muxer?.release()
            file.delete()
            return
        }
        val pcm = ShortArray(CHUNK)
        var written = 0L

        // Auto: measure each source for TEST_SAMPLES, then settle on the loudest.
        val testing = sources.size > 1
        val levels = LinkedHashMap<Int, Double>()
        var testIndex = sources.indexOf(firstSource)
        var testSum = 0.0
        var testCount = 0L
        var current = firstSource
        // Once settled: is the source silent (blocked) for its first SILENCE_SAMPLES?
        var silenceSum = 0.0
        var silenceCount = 0L
        var settled = !testing

        try {
            while (running) {
                val n = record?.read(pcm, 0, CHUNK) ?: break
                // A dead or revoked microphone answers with the same error forever: end the file
                // with what was heard rather than spin on it.
                if (n < 0) break
                if (n == 0) continue
                var squares = 0.0
                for (i in 0 until n) squares += pcm[i].toDouble() * pcm[i]
                if (!settled) {
                    testSum += squares
                    testCount += n
                    if (testCount >= TEST_SAMPLES) {
                        levels[current] = SourcePicker.rms(testSum, testCount)
                        testSum = 0.0
                        testCount = 0
                        // Next untested source that opens, else pick the best and stay there.
                        var moved = false
                        while (!moved && testIndex + 1 < sources.size) {
                            testIndex++
                            if (switchTo(sources[testIndex])) {
                                current = sources[testIndex]
                                moved = true
                            }
                        }
                        if (!moved) {
                            val best = SourcePicker.best(levels) ?: current
                            if (best != current && switchTo(best)) current = best
                            onSourceChosen(current)
                            settled = true
                        }
                    }
                } else if (silenceCount < SILENCE_SAMPLES) {
                    silenceSum += squares
                    silenceCount += n
                    if (silenceCount >= SILENCE_SAMPLES && SourcePicker.rms(silenceSum, silenceCount) < SourcePicker.SILENCE_RMS) onSilent()
                }
                compressor.process(pcm, n)
                writer.feed(pcm, n, written * 1_000_000L / RATE)
                written += n
            }
            writer.finish(written * 1_000_000L / RATE)
        } finally {
            gain?.release()
            record?.run { stop(); release() }
            record = null
            codec?.release()
            try {
                if (writer.started) muxer?.stop()
            } catch (_: IllegalStateException) {
            }
            muxer?.release()
            if (!writer.started) file.delete() // nothing was recorded
        }
    }

    /** Feeds PCM into the encoder and moves encoded frames into the muxer. */
    private class Writer(private val codec: MediaCodec, private val muxer: MediaMuxer) {
        private val info = MediaCodec.BufferInfo()
        private var track = -1
        var started = false
            private set

        fun feed(pcm: ShortArray, count: Int, timeUs: Long) {
            val index = codec.dequeueInputBuffer(10_000)
            if (index >= 0) {
                val buffer = codec.getInputBuffer(index)!!
                buffer.clear()
                buffer.order(java.nio.ByteOrder.LITTLE_ENDIAN).asShortBuffer().put(pcm, 0, count)
                codec.queueInputBuffer(index, 0, count * 2, timeUs, 0)
            }
            drain(false)
        }

        fun finish(timeUs: Long) {
            val index = codec.dequeueInputBuffer(10_000)
            if (index >= 0) codec.queueInputBuffer(index, 0, 0, timeUs, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
            drain(true)
        }

        private fun drain(toEnd: Boolean) {
            while (true) {
                val index = codec.dequeueOutputBuffer(info, if (toEnd) 10_000 else 0)
                when {
                    index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        track = muxer.addTrack(codec.outputFormat)
                        muxer.start()
                        started = true
                    }
                    index >= 0 -> {
                        val data = codec.getOutputBuffer(index)!!
                        val config = info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0
                        if (started && !config && info.size > 0) muxer.writeSampleData(track, data, info)
                        codec.releaseOutputBuffer(index, false)
                        if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) return
                    }
                    index == MediaCodec.INFO_TRY_AGAIN_LATER && !toEnd -> return
                    index == MediaCodec.INFO_TRY_AGAIN_LATER -> return // shortcut: an encoder that never signals the end loses its last few ms
                }
            }
        }
    }

    private companion object {
        const val RATE = 48_000
        const val CHUNK = 1024 // ~21 ms per read
        const val TEST_SAMPLES = RATE.toLong() // about a second per source
        const val SILENCE_SAMPLES = RATE * 5L
    }
}
