import { ClosingCta } from "@/components/home/closing-cta";
import { FlightPlan } from "@/components/home/flight-plan";
import { HelpLinks } from "@/components/home/help-links";
import { Hero } from "@/components/home/hero";
import { ScoreAnatomy } from "@/components/home/score-anatomy";
import { Stations } from "@/components/home/stations";

/**
 * Homepage (plan/ui/public-site/homepage.md): what RC Soar Score is, the
 * three navigation elements (Contests, Documentation, Login) and the product
 * story, in the order a visitor asks the questions.
 */
export default function HomePage() {
  return (
    <>
      <Hero />
      <Stations />
      <FlightPlan />
      <ScoreAnatomy />
      <HelpLinks />
      <ClosingCta />
    </>
  );
}
