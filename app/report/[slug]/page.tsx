import { promises as fs } from "fs";
import path from "path";
import { Metadata } from "next";
import { notFound } from "next/navigation";
import { DetailedView } from "../../../components/DetailedView";
import { Navbar } from "../../../components/Navbar";

interface Props {
  params: { slug: string };
}

async function getReport(slug: string) {
  try {
    const filePath = path.join(process.cwd(), "public", "data", `${slug}.json`);
    const fileContents = await fs.readFile(filePath, "utf8");
    return JSON.parse(fileContents);
  } catch (e) {
    return null;
  }
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const report = await getReport(params.slug);

  if (!report) {
    return {};
  }

  const title = `${report.public.title} | Factline`;
  const description = report.public.summary;
  const image = report.metadata?.cover_image ? `https://factline.one${report.metadata.cover_image}` : `https://factline.one/data/assets/${params.slug}/cover_image.jpg`;

  return {
    title,
    description,
    openGraph: {
      title,
      description,
      images: [{ url: image }],
      type: "article",
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: [image],
    },
  };
}

export default async function ReportPage({ params }: Props) {
  const report = await getReport(params.slug);

  if (!report) {
    notFound();
  }

  if (!report.metadata) report.metadata = {};
  if (!report.metadata.cover_image) {
    report.metadata.cover_image = `/data/assets/${params.slug}/cover_image.jpg`;
  }

  return (
    <>
      {/* Deep Dark Dynamic Background */}
      <div className="fixed inset-0 z-0 overflow-hidden pointer-events-none">
        <div className="absolute top-[-20%] left-[-10%] w-[50%] h-[50%] bg-[#A259FF]/10 rounded-full blur-[150px]" />
        <div className="absolute bottom-[-20%] right-[-10%] w-[50%] h-[50%] bg-blue-500/5 rounded-full blur-[150px]" />
      </div>

      <Navbar />

      <main className="relative z-10 pt-0">
        <DetailedView report={report} />
      </main>
    </>
  );
}
