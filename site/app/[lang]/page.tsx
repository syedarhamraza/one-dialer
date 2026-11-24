import { Home, homeMetadata } from "@/components/Home";
import { type Params, translated } from "./params";

export const dynamicParams = false;
export const generateStaticParams = translated;
export const generateMetadata = async ({ params }: Params) => homeMetadata((await params).lang);

export default async function OneDialer({ params }: Params) {
  return <Home lang={(await params).lang} />;
}
