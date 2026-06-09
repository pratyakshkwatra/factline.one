import { promises as fs } from 'fs';
import path from 'path';
import { Navbar } from '../../components/Navbar';
import { ReportList } from '../../components/ReportList';
import { Report } from '../../components/ReportCardView';
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Intelligence Archive | Factline',
  description: 'Every investigation. Every claim. Every source. Permanently archived.',
};

async function getReports(): Promise<Report[]> {
  try {
    const filePath = path.join(process.cwd(), 'public', 'data', 'index.json');
    const contents = await fs.readFile(filePath, 'utf8');
    const reports: Report[] = JSON.parse(contents);
    return reports.sort(
      (a, b) => new Date(b.published_at).getTime() - new Date(a.published_at).getTime()
    );
  } catch {
    return [];
  }
}

export default async function ArchivePage() {
  const reports = await getReports();

  return (
    <>
      {/* Ambient background */}
      <div className="fixed inset-0 z-0 overflow-hidden pointer-events-none">
        <div className="absolute top-[-20%] left-[-10%] w-[50%] h-[50%] bg-[#A259FF]/8 rounded-full blur-[180px]" />
        <div className="absolute bottom-[-20%] right-[-10%] w-[50%] h-[50%] bg-blue-500/5 rounded-full blur-[200px]" />
      </div>

      <Navbar />

      <main className="relative z-10 pt-[68px]">
        <ReportList initialReports={reports} />
      </main>
    </>
  );
}
