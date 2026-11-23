import { DialerGuide, guideMetadata } from "@/components/DialerGuide";
import { type Params, translated } from "../params";

export const dynamicParams = false;
export const generateStaticParams = translated;
export const generateMetadata = async ({ params }: Params) => guideMetadata((await params).lang);

export default async function Guide({ params }: Params) {
  return <DialerGuide lang={(await params).lang} />;
}
