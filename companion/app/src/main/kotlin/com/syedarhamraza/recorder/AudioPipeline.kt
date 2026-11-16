package com.syedarhamraza.recorder

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.File
import java.io.IOException
import java.io.InputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Both sides: the shell helper's 48 kHz mono 16-bit PCM ([input]) → AAC (MediaCodec) → .m4a
 * (MediaMuxer), on its own thread. The microphone method records with MediaRecorder instead.
 */
class AudioPipeline(private val file: File, private val input: InputStream) {
    @Volatile private var running = false
    private var thread: Thread? = null

    fun start() {
        running = true
        thread = Thread(::loop, "recorder").apply { start() }
    }

    /** Finishes the file; blocks until the encoder has written its last frame. */
    fun stop() {
        running = false
        runCatching { input.close() } // unblocks a read waiting on the helper
        thread?.join(3000)
        thread = null
    }

    private fun loop() {
        // An encoder or file that won't open must not take the process down (an uncaught exception
        // on this thread would) with the helper still recording.
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
            codec?.release()
            muxer?.release()
            file.delete()
            return
        }
        val pcm = ShortArray(CHUNK)
        var written = 0L

        try {
            while (running) {
                val n = read(pcm)
                if (n < 0) break // the helper hung up
                if (n == 0) continue
                writer.feed(pcm, n, written * 1_000_000L / RATE)
                written += n
            }
            writer.finish(written * 1_000_000L / RATE)
        } finally {
            codec?.release()
            try {
                if (writer.started) muxer?.stop()
            } catch (_: IllegalStateException) {
            }
            muxer?.release()
            if (!writer.started) file.delete() // nothing was recorded
        }
    }

    private val bytes = ByteArray(CHUNK * 2)

    /** Samples read into [pcm]; negative once the source has ended. */
    private fun read(pcm: ShortArray): Int {
        var n = try { input.read(bytes, 0, bytes.size) } catch (_: IOException) { -1 }
        if (n <= 0) return -1
        if (n % 2 == 1) { // half a sample: wait for its other byte
            val b = try { input.read() } catch (_: IOException) { -1 }
            if (b < 0) n-- else bytes[n++] = b.toByte()
        }
        ByteBuffer.wrap(bytes, 0, n).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer().get(pcm, 0, n / 2)
        return n / 2
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
    }
}
