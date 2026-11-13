import { GooglePlayLogoIcon } from "@phosphor-icons/react/dist/ssr";
import { PLAY_URL } from "@/app/links";

/** The released site's call to action: the lit green button that opens One Dialer on Google Play. */
export function PlayButton({ className = "" }: { className?: string }) {
  return (
    <a href={PLAY_URL} target="_blank" rel="noopener noreferrer" className={`lit press inline-flex h-14 items-center gap-3 rounded-full px-7 text-[16px] font-semibold ${className}`}>
      <GooglePlayLogoIcon size={22} weight="fill" />
      Get it on Google Play
    </a>
  );
}
