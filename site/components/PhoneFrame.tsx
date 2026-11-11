import Image from "next/image";
import { BatteryFullIcon, CellSignalFullIcon, WifiHighIcon } from "@phosphor-icons/react/dist/ssr";

/** A plain device frame around a real app capture (status bar cropped by scripts/assets.mjs). */
export function PhoneFrame({
  src,
  alt,
  priority = false,
  className = "",
  children,
}: {
  src: string;
  alt: string;
  priority?: boolean;
  className?: string;
  /** Overlays positioned against the screen (e.g. a highlight on part of the capture). */
  children?: React.ReactNode;
}) {
  return (
    <div
      className={`relative aspect-[9/19.5] rounded-[14%/6.5%] bg-[#0b0b0c] p-[3.2%] shadow-[0_40px_120px_-30px_rgb(3_129_254/0.35),0_0_0_1px_rgb(255_255_255/0.07)] ${className}`}
    >
      <div className="relative h-full w-full overflow-hidden rounded-[11.5%/5.3%] bg-black">
        <div className="flex h-[5.4%] items-center justify-between px-[8%] text-[clamp(7px,1.15cqw,12px)] font-semibold text-white [container-type:inline-size]">
          <span className="tabular text-[0.75rem] max-md:text-[0.6rem]">9:41</span>
          <span className="flex items-center gap-1">
            <CellSignalFullIcon size={12} weight="fill" />
            <WifiHighIcon size={12} weight="bold" />
            <BatteryFullIcon size={14} weight="fill" />
          </span>
        </div>
        <span className="absolute top-[1.4%] left-1/2 h-[2.6%] w-[5.8%] -translate-x-1/2 rounded-full bg-[#0b0b0c]" />
        <Image
          src={src}
          alt={alt}
          width={720}
          height={1531}
          priority={priority}
          className="block h-[94.6%] w-full object-cover object-top"
          sizes="(max-width: 768px) 70vw, 360px"
        />
        {children}
      </div>
    </div>
  );
}
