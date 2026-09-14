#!/usr/bin/env bun

import { existsSync } from "node:fs";
import { basename } from "node:path";

type PatternFinding = {
  line: number;
  text: string;
  match: string;
  position: number;
};

type StructureFinding = {
  issue: string;
  description: string;
};

type Findings = {
  high_risk: PatternFinding[];
  medium_risk: PatternFinding[];
  buzzwords: PatternFinding[];
  meta_commentary: PatternFinding[];
  hedging: PatternFinding[];
  structure: StructureFinding[];
};

const highRiskPhrases = [
  /delve into/gi,
  /dive deep into/gi,
  /unpack/gi,
  /navigate the complexit(?:y|ies)/gi,
  /in the ever-evolving landscape/gi,
  /in today's fast-paced world/gi,
  /in today's digital age/gi,
  /at the end of the day/gi,
  /it'?s important to note that/gi,
  /it'?s worth noting that/gi,
];

const mediumRiskPhrases = [
  /however,? it is important to/gi,
  /furthermore/gi,
  /moreover/gi,
  /in essence/gi,
  /essentially/gi,
  /fundamentally/gi,
  /ultimately/gi,
  /that being said/gi,
];

const buzzwords = [
  /synergistic/gi,
  /holistic approach/gi,
  /paradigm shift/gi,
  /game-changer/gi,
  /revolutionary/gi,
  /cutting-edge/gi,
  /next-generation/gi,
  /world-class/gi,
  /best-in-class/gi,
  /leverage/gi,
  /utilize/gi,
  /empower/gi,
  /unlock potential/gi,
  /drive innovation/gi,
];

const metaCommentary = [
  /in this (?:article|post|document|section)/gi,
  /as we (?:explore|examine|discuss|delve)/gi,
  /let'?s take a (?:closer )?look/gi,
  /now that we'?ve covered/gi,
  /before we proceed/gi,
  /it'?s crucial to understand/gi,
];

const hedgeWords = [
  /may or may not/gi,
  /could potentially/gi,
  /might possibly/gi,
  /it appears that/gi,
  /it seems that/gi,
  /one could argue/gi,
  /some might say/gi,
  /to a certain extent/gi,
  /generally speaking/gi,
];

function emptyFindings(): Findings {
  return {
    high_risk: [],
    medium_risk: [],
    buzzwords: [],
    meta_commentary: [],
    hedging: [],
    structure: [],
  };
}

class SlopDetector {
  private text = "";
  private lines: string[] = [];
  private findings = emptyFindings();

  constructor(private filepath: string) {}

  async load(): Promise<void> {
    this.text = await Bun.file(this.filepath).text();
    this.lines = this.text.split("\n");
  }

  analyze() {
    this.findPatterns(highRiskPhrases, "high_risk");
    this.findPatterns(mediumRiskPhrases, "medium_risk");
    this.findPatterns(buzzwords, "buzzwords");
    this.findPatterns(metaCommentary, "meta_commentary");
    this.findPatterns(hedgeWords, "hedging");
    this.analyzeStructure();

    const score = this.calculateSlopScore();

    return {
      findings: this.findings,
      score,
      summary: this.generateSummary(score),
    };
  }

  printReport(verbose = false): void {
    const results = this.analyze();
    const findings = results.findings;

    console.log(`\n${"=".repeat(70)}`);
    console.log(`AI Slop Detection Report: ${basename(this.filepath)}`);
    console.log(`${"=".repeat(70)}\n`);
    console.log(`Overall Slop Score: ${results.score}/100`);
    console.log(`Assessment: ${results.summary}\n`);

    if (findings.high_risk.length > 0) {
      console.log(`🔴 HIGH-RISK PHRASES (${findings.high_risk.length} found):`);
      for (const finding of limitFindings(findings.high_risk, verbose, 5)) {
        console.log(
          `  Line ${finding.line}: '${finding.match}' in: ${finding.text.slice(0, 60)}...`,
        );
      }
      if (findings.high_risk.length > 5 && !verbose) {
        console.log(`  ... and ${findings.high_risk.length - 5} more`);
      }
      console.log();
    }

    if (findings.buzzwords.length > 0) {
      console.log(
        `📢 BUZZWORDS & JARGON (${findings.buzzwords.length} found):`,
      );
      if (!verbose) {
        const uniqueBuzzwords = [
          ...new Set(findings.buzzwords.map((finding) => finding.match)),
        ];
        console.log(`  ${uniqueBuzzwords.slice(0, 10).join(", ")}`);
        if (uniqueBuzzwords.length > 10) {
          console.log(
            `  ... and ${uniqueBuzzwords.length - 10} more unique buzzwords`,
          );
        }
      } else {
        for (const finding of findings.buzzwords) {
          console.log(`  Line ${finding.line}: '${finding.match}'`);
        }
      }
      console.log();
    }

    if (findings.meta_commentary.length > 0) {
      console.log(
        `📝 META-COMMENTARY (${findings.meta_commentary.length} found):`,
      );
      for (const finding of limitFindings(
        findings.meta_commentary,
        verbose,
        3,
      )) {
        console.log(`  Line ${finding.line}: ${finding.text.slice(0, 70)}...`);
      }
      if (findings.meta_commentary.length > 3 && !verbose) {
        console.log(`  ... and ${findings.meta_commentary.length - 3} more`);
      }
      console.log();
    }

    if (findings.structure.length > 0) {
      console.log("🏗️  STRUCTURAL ISSUES:");
      for (const finding of findings.structure) {
        console.log(`  • ${finding.issue}: ${finding.description}`);
      }
      console.log();
    }

    if (findings.hedging.length > 0) {
      console.log(`🤔 EXCESSIVE HEDGING (${findings.hedging.length} found)`);
      if (!verbose) {
        const lineCount = new Set(
          findings.hedging.map((finding) => finding.line),
        ).size;
        console.log(`  Found in ${lineCount} lines`);
      } else {
        for (const finding of findings.hedging.slice(0, 5)) {
          console.log(`  Line ${finding.line}: '${finding.match}'`);
        }
      }
      console.log();
    }

    if (results.score > 20) {
      console.log("💡 RECOMMENDATIONS:");
      if (findings.high_risk.length > 0) {
        console.log(
          "  • Replace high-risk phrases with direct, specific language",
        );
      }
      if (findings.buzzwords.length > 0) {
        console.log("  • Remove buzzwords and use concrete, specific terms");
      }
      if (findings.meta_commentary.length > 0) {
        console.log("  • Delete meta-commentary; lead with actual content");
      }
      if (findings.hedging.length > 0) {
        console.log(
          "  • Reduce hedging; be direct and confident in statements",
        );
      }
      if (findings.structure.length > 0) {
        console.log("  • Restructure document to avoid generic AI patterns");
      }
      console.log();
    }
  }

  private findPatterns(
    patterns: RegExp[],
    category: keyof Omit<Findings, "structure">,
  ): void {
    this.lines.forEach((line, index) => {
      for (const pattern of patterns) {
        pattern.lastIndex = 0;
        for (const match of line.matchAll(pattern)) {
          this.findings[category].push({
            line: index + 1,
            text: line.trim(),
            match: match[0],
            position: match.index ?? 0,
          });
        }
      }
    });
  }

  private analyzeStructure(): void {
    if (this.lines.length > 0) {
      const firstPara = this.lines.slice(0, 5).join(" ");
      if (/in this .+ (?:will|we)/i.test(firstPara)) {
        this.findings.structure.push({
          issue: "Opening meta-commentary",
          description:
            "Document starts with meta-commentary instead of content",
        });
      }
    }

    const transitions = [
      "however",
      "furthermore",
      "moreover",
      "additionally",
      "nevertheless",
      "consequently",
      "therefore",
    ];
    const nonEmptyLines = this.lines.filter((line) => line.trim().length > 0);
    const transitionStarters = nonEmptyLines.filter((line) => {
      const lower = line.trim().toLowerCase();
      return transitions.some((transition) => lower.startsWith(transition));
    }).length;

    if (this.lines.length > 0) {
      const transitionRatio = transitionStarters / nonEmptyLines.length;
      if (transitionRatio > 0.3) {
        this.findings.structure.push({
          issue: "Excessive transitions",
          description: `${Math.round(transitionRatio * 100)}% of paragraphs start with transition words`,
        });
      }
    }
  }

  private calculateSlopScore(): number {
    let score = 0;
    score += this.findings.high_risk.length * 15;
    score += this.findings.medium_risk.length * 8;
    score += this.findings.buzzwords.length * 5;
    score += this.findings.meta_commentary.length * 10;
    score += this.findings.hedging.length * 6;
    score += this.findings.structure.length * 20;

    const wordCount = this.text.split(/\s+/).filter(Boolean).length;
    if (wordCount > 0) {
      score = Math.trunc((score / wordCount) * 1000);
    }

    return Math.min(score, 100);
  }

  private generateSummary(score: number): string {
    if (score < 20) {
      return "✅ Low slop detected - Writing appears authentic and purposeful";
    }
    if (score < 40) {
      return "⚠️  Moderate slop detected - Some generic patterns present";
    }
    if (score < 60) {
      return "🚨 High slop detected - Many AI-generated patterns found";
    }
    return "💀 Severe slop detected - Document heavily relies on generic AI patterns";
  }
}

function limitFindings(
  findings: PatternFinding[],
  verbose: boolean,
  limit: number,
): PatternFinding[] {
  return verbose ? findings : findings.slice(0, limit);
}

async function main(): Promise<void> {
  const args = Bun.argv.slice(2);
  if (args.length < 1) {
    console.log("Usage: bun detect_slop.ts <file> [--verbose]");
    console.log("Analyzes text files for AI-generated content patterns");
    process.exit(1);
  }

  const filepath = args[0];
  const verbose = args.includes("--verbose") || args.includes("-v");

  if (!existsSync(filepath)) {
    console.log(`Error: File '${filepath}' not found`);
    process.exit(1);
  }

  const detector = new SlopDetector(filepath);
  await detector.load();
  detector.printReport(verbose);
}

await main();
