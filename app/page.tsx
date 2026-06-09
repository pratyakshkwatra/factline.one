import { promises as fs } from 'fs';
import path from 'path';
import { Navbar } from '../components/Navbar';
import { LandingPage } from '../components/LandingPage';
import { Report } from '../components/ReportCardView';

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

async function getFeaturedReport(reports: Report[]) {
  if (reports.length === 0) return null;
  // Always the most recent report — dynamically loads its full JSON
  const newest = reports[0];
  try {
    const filePath = path.join(process.cwd(), 'public', 'data', `${newest.slug}.json`);
    const contents = await fs.readFile(filePath, 'utf8');
    const full = JSON.parse(contents);
    // Attach the slug so the component can build the route
    full.slug = newest.slug;
    return full;
  } catch {
    return null;
  }
}

export default async function Home() {
  const reports        = await getReports();
  const featuredReport = await getFeaturedReport(reports);

  return (
    <>
      <Navbar />
      <main className="relative z-10 pt-[68px]">
        <LandingPage reports={reports} featuredReport={featuredReport} />
      </main>
    </>
  );
}
