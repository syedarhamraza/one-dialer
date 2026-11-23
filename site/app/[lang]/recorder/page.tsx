import { RecorderGuide, recorderMetadata } from "@/components/RecorderGuide";
import { type Params, translated } from "../params";

export const dynamicParams = false;
export const generateStaticParams = translated;
export const generateMetadata = async ({ params }: Params) => recorderMetadata((await params).lang);

export default async function OneRecorder({ params }: Params) {
  return <RecorderGuide lang={(await params).lang} />;
}
