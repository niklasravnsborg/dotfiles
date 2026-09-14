#!/usr/bin/env bun

import { existsSync, renameSync, writeFileSync } from "node:fs";
import { basename } from "node:path";

type Replacement = [RegExp, string];

class SlopCleaner {
  private text = "";
  private changesMade: string[] = [];

  constructor(
    private filepath: string,
    private aggressive = false,
  ) {}

  async load(): Promise<void> {
    this.text = await Bun.file(this.filepath).text();
  }

  clean(): string {
    let cleaned = this.text;

    cleaned = this.removeHighRiskPhrases(cleaned);
    cleaned = this.simplifyWordyPhrases(cleaned);
    cleaned = this.removeMetaCommentary(cleaned);
    cleaned = this.reduceHedging(cleaned);
    cleaned = this.cleanBuzzwords(cleaned);
    cleaned = this.fixRedundantQualifiers(cleaned);
    cleaned = this.removeEmptyIntensifiers(cleaned);

    if (this.aggressive) {
      cleaned = this.aggressiveCleanup(cleaned);
    }

    return this.normalizeSpacing(cleaned);
  }

  save(outputPath?: string): void {
    const cleaned = this.clean();
    let destination = outputPath;

    if (destination === undefined) {
      const backupPath = `${this.filepath}.backup`;
      renameSync(this.filepath, backupPath);
      destination = this.filepath;
      console.log(`✅ Created backup: ${backupPath}`);
    }

    writeFileSync(destination, cleaned, "utf8");
    console.log(`✅ Saved cleaned text to: ${destination}`);
    console.log(`\n📊 Changes made: ${this.changesMade.length}`);

    if (this.changesMade.length > 0) {
      console.log("\nSummary of changes:");
      const changeCounts = new Map<string, number>();
      for (const change of this.changesMade) {
        const category = change.split(":")[0];
        changeCounts.set(category, (changeCounts.get(category) ?? 0) + 1);
      }

      for (const [category, count] of changeCounts) {
        console.log(`  • ${category}: ${count} instance(s)`);
      }
    }
  }

  preview(): void {
    const cleaned = this.clean();

    if (cleaned === this.text) {
      console.log("✅ No changes needed - text is already clean!");
      return;
    }

    console.log(`\n${"=".repeat(70)}`);
    console.log(`Preview of changes for: ${basename(this.filepath)}`);
    console.log(`${"=".repeat(70)}\n`);

    const originalLines = this.text.split("\n");
    const cleanedLines = cleaned.split("\n");
    let changesShown = 0;
    const maxChangesToShow = 10;

    for (
      let index = 0;
      index < Math.min(originalLines.length, cleanedLines.length);
      index += 1
    ) {
      const original = originalLines[index];
      const clean = cleanedLines[index];
      if (original !== clean && changesShown < maxChangesToShow) {
        console.log(`Line ${index + 1}:`);
        console.log(`  - ${original.slice(0, 80)}`);
        console.log(`  + ${clean.slice(0, 80)}`);
        console.log();
        changesShown += 1;
      }
    }

    if (changesShown === maxChangesToShow) {
      console.log(`... and more changes (showing first ${maxChangesToShow})`);
    }

    console.log(`\n📊 Total changes: ${this.changesMade.length}`);
    console.log("\nRun with --save to apply changes");
  }

  private applyReplacements(
    text: string,
    replacements: Replacement[],
    changeMessage: (pattern: RegExp, replacement: string) => string,
  ): string {
    let updated = text;
    for (const [pattern, replacement] of replacements) {
      const oldText = updated;
      updated = updated.replace(pattern, replacement);
      if (updated !== oldText) {
        this.changesMade.push(changeMessage(pattern, replacement));
      }
    }
    return updated;
  }

  private removeHighRiskPhrases(text: string): string {
    return this.applyReplacements(
      text,
      [
        [/\b(?:delve|dive deep) into\b/gi, ""],
        [/\bunpack\b(?! (?:the|a|an))/gi, "examine"],
        [/\bnavigate the complexit(?:y|ies) of\b/gi, "handle"],
        [/\bin the ever-evolving landscape of\b/gi, "in"],
        [/\bin today's fast-paced world,?\b/gi, ""],
        [/\bin today's digital age,?\b/gi, ""],
        [/\bat the end of the day,?\b/gi, "ultimately"],
        [/\bit's important to note that\b/gi, ""],
        [/\bit's worth noting that\b/gi, ""],
      ],
      (pattern) => `Removed/replaced: ${pattern.source}`,
    );
  }

  private simplifyWordyPhrases(text: string): string {
    return this.applyReplacements(
      text,
      [
        [/\bin order to\b/gi, "to"],
        [/\bdue to the fact that\b/gi, "because"],
        [/\bat this point in time\b/gi, "now"],
        [/\bfor the purpose of\b/gi, "for"],
        [/\bhas the ability to\b/gi, "can"],
        [/\bis able to\b/gi, "can"],
        [/\bin spite of the fact that\b/gi, "although"],
        [/\btake into consideration\b/gi, "consider"],
        [/\bmake a decision\b/gi, "decide"],
        [/\bconduct an investigation\b/gi, "investigate"],
        [/\bin the event that\b/gi, "if"],
        [/\bprior to\b/gi, "before"],
        [/\bsubsequent to\b/gi, "after"],
      ],
      (pattern, replacement) =>
        `Simplified: '${pattern.source}' -> '${replacement}'`,
    );
  }

  private removeMetaCommentary(text: string): string {
    let updated = text;
    const patterns = [
      /In this (?:article|post|document|section|guide),? (?:we will|I will|we|I) .*?[.!]\s*/gi,
      /As we (?:explore|examine|discuss|delve into) .*?,?\s/gi,
      /Let's take a (?:closer )?look at .*?[.!]\s*/gi,
      /Now that we've covered .*?,?\s/gi,
      /Before we proceed,?\s.*?[.!]\s*/gi,
    ];

    for (const pattern of patterns) {
      const oldText = updated;
      updated = updated.replace(pattern, "");
      if (updated !== oldText) {
        this.changesMade.push("Removed meta-commentary");
      }
    }

    return updated;
  }

  private reduceHedging(text: string): string {
    return this.applyReplacements(
      text,
      [
        [/\bmay or may not\b/gi, "may"],
        [/\bcould potentially\b/gi, "could"],
        [/\bmight possibly\b/gi, "might"],
        [/\bit appears that\b/gi, ""],
        [/\bit seems that\b/gi, ""],
        [/\bone could argue that\b/gi, ""],
        [/\bsome might say that\b/gi, ""],
        [/\bto a certain extent,?\b/gi, ""],
        [/\bgenerally speaking,?\b/gi, ""],
      ],
      (pattern) => `Reduced hedging: ${pattern.source}`,
    );
  }

  private cleanBuzzwords(text: string): string {
    return this.applyReplacements(
      text,
      [
        [/\bleverag(?:e|ing)\b/gi, "use"],
        [/\butiliz(?:e|ing)\b/gi, "use"],
        [/\bsynergistic\b/gi, "cooperative"],
        [/\bparadigm shift\b/gi, "major change"],
        [/\bgame-changer\b/gi, "significant"],
        [/\bnext-generation\b/gi, "new"],
        [/\bworld-class\b/gi, "excellent"],
        [/\bbest-in-class\b/gi, "excellent"],
        [/\bcutting-edge\b/gi, "advanced"],
      ],
      (pattern) => `Replaced buzzword: ${pattern.source}`,
    );
  }

  private fixRedundantQualifiers(text: string): string {
    return this.applyReplacements(
      text,
      [
        [/\bcompletely finish(?:ed)?\b/gi, "finished"],
        [/\babsolutely essential\b/gi, "essential"],
        [/\btotally unique\b/gi, "unique"],
        [/\bvery unique\b/gi, "unique"],
        [/\bpast history\b/gi, "history"],
        [/\bfuture plans\b/gi, "plans"],
        [/\bend result\b/gi, "result"],
        [/\bfinal outcome\b/gi, "outcome"],
      ],
      (pattern) => `Fixed redundant qualifier: ${pattern.source}`,
    );
  }

  private removeEmptyIntensifiers(text: string): string {
    return this.applyReplacements(
      text,
      [
        [/\breally important\b/gi, "important"],
        [/\bvery important\b/gi, "important"],
        [/\bquite literally\b/gi, "literally"],
        [/\bactually,?\s(?!not|the|a)\b/gi, ""],
      ],
      () => "Removed empty intensifier",
    );
  }

  private aggressiveCleanup(text: string): string {
    let cleaned = text;
    cleaned = cleaned.replace(/^However,\s/gm, "");
    cleaned = cleaned.replace(/^Furthermore,\s/gm, "");
    cleaned = cleaned.replace(/^Moreover,\s/gm, "");
    cleaned = cleaned.replace(
      /\bIt is (?:important|crucial|essential|vital) (?:that|to)\b/gi,
      "",
    );
    this.changesMade.push("Applied aggressive cleanup");
    return cleaned;
  }

  private normalizeSpacing(text: string): string {
    let cleaned = text;
    cleaned = cleaned.replace(/ {2,}/g, " ");
    cleaned = cleaned.replace(/ +([.,;:!?])/g, "$1");
    cleaned = cleaned.replace(/\n{3,}/g, "\n\n");
    cleaned = cleaned.replace(
      /([.!?])\s+([a-z])/g,
      (_match, punctuation: string, letter: string) => {
        return `${punctuation} ${letter.toUpperCase()}`;
      },
    );
    cleaned = cleaned.replace(/,\s*,/g, ",");
    return cleaned.trim();
  }
}

async function main(): Promise<void> {
  const args = Bun.argv.slice(2);

  if (args.length < 1) {
    console.log("Usage: bun clean_slop.ts <file> [options]");
    console.log("\nOptions:");
    console.log("  --save           Save changes (creates backup)");
    console.log("  --output FILE    Save to different file");
    console.log("  --aggressive     More aggressive cleanup");
    console.log("  --preview        Preview changes without saving (default)");
    process.exit(1);
  }

  const filepath = args[0];

  if (!existsSync(filepath)) {
    console.log(`Error: File '${filepath}' not found`);
    process.exit(1);
  }

  const outputIndex = args.indexOf("--output");
  const outputFile =
    outputIndex >= 0 && outputIndex + 1 < args.length
      ? args[outputIndex + 1]
      : undefined;
  const cleaner = new SlopCleaner(filepath, args.includes("--aggressive"));
  await cleaner.load();

  if (args.includes("--save") || outputFile !== undefined) {
    cleaner.save(outputFile);
  } else {
    cleaner.preview();
  }
}

await main();
