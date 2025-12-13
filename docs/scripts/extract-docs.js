#!/usr/bin/env node
/**
 * Extracts documentation from D source files and generates Starlight-compatible Markdown.
 *
 * Parses:
 * - static immutable *Description strings
 * - /// ddoc comments
 * - @("test name") unittest blocks for examples
 * - static foreach type patterns
 */

import { readFileSync, writeFileSync, readdirSync, mkdirSync, existsSync } from 'fs';
import { join, dirname, basename } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const sourceRoot = join(__dirname, '..', '..', 'source', 'fluentasserts', 'operations');
const outputRoot = join(__dirname, '..', 'src', 'content', 'docs', 'api');

// Map source folder names to doc category names
const folderToCategoryMap = {
  'comparison': 'comparison',
  'equality': 'equality',
  'exception': 'callable',
  'memory': 'callable',
  'string': 'strings',
  'type': 'types',
  'operations': 'other', // root level files like snapshot.d
};

// Get category from file path
function getCategoryFromPath(filePath) {
  const parts = filePath.split('/');
  const operationsIndex = parts.indexOf('operations');
  if (operationsIndex >= 0 && operationsIndex < parts.length - 2) {
    const folder = parts[operationsIndex + 1];
    return folderToCategoryMap[folder] || 'other';
  }
  return 'other';
}

/**
 * Parse a D source file and extract documentation
 */
function parseSourceFile(filePath) {
  const content = readFileSync(filePath, 'utf-8');
  const fileName = basename(filePath, '.d');

  const doc = {
    name: fileName,
    filePath: filePath,
    description: '',
    ddocComment: '',
    examples: [],
    supportedTypes: [],
    aliases: [],
    hasNegation: false,
    functionName: '',
  };

  // Extract main function name (e.g., allocateGCMemory, equal, etc.)
  const funcMatch = content.match(/void\s+(\w+)\s*\(\s*ref\s+Evaluation/);
  if (funcMatch) {
    doc.functionName = funcMatch[1];
  }

  // Extract description string: static immutable *Description = "...";
  const descMatch = content.match(/static\s+immutable\s+\w*[Dd]escription\s*=\s*"([^"]+)"/);
  if (descMatch) {
    doc.description = descMatch[1];
  }

  // Extract ddoc comments before the main function
  const ddocMatch = content.match(/\/\/\/\s*([^\n]+(?:\n\/\/\/\s*[^\n]+)*)\s*\n\s*(?:@\w+\s+)*void\s+\w+\s*\(/);
  if (ddocMatch) {
    doc.ddocComment = ddocMatch[1]
      .split('\n')
      .map(line => line.replace(/^\/\/\/\s*/, '').trim())
      .join(' ');
  }

  // Extract unittest examples
  const unittestRegex = /@\("([^"]+)"\)\s*unittest\s*\{([\s\S]*?)\n\s*\}/g;
  let match;
  while ((match = unittestRegex.exec(content)) !== null) {
    const testName = match[1];
    const testBody = match[2];

    // Check for negation tests
    if (testName.includes('not') || testBody.includes('.not.')) {
      doc.hasNegation = true;
    }

    // Extract expect() calls as examples
    const expectCalls = testBody.match(/expect\([^)]+\)[^;]+;/g);
    if (expectCalls) {
      doc.examples.push({
        name: testName,
        code: expectCalls.map(c => c.trim()).join('\n'),
        isNegation: testBody.includes('.not.'),
        isFailure: testName.toLowerCase().includes('fail') ||
                   testName.toLowerCase().includes('error') ||
                   testBody.includes('recordEvaluation'),
      });
    }
  }

  // Extract type aliases from static foreach
  const typeMatch = content.match(/static\s+foreach\s*\(\s*Type\s*;\s*AliasSeq!\(([^)]+)\)/);
  if (typeMatch) {
    doc.supportedTypes = typeMatch[1]
      .split(',')
      .map(t => t.trim())
      .filter(t => t);
  }

  // Check for aliases (methods with same implementation)
  const aliasMatches = content.matchAll(/alias\s+(\w+)\s*=\s*(\w+)/g);
  for (const aliasMatch of aliasMatches) {
    if (aliasMatch[2].toLowerCase() === fileName.toLowerCase()) {
      doc.aliases.push(aliasMatch[1]);
    }
  }

  return doc;
}

/**
 * Generate Markdown documentation for an operation
 */
function generateMarkdown(doc) {
  const lines = [];
  const displayName = doc.functionName || doc.name;

  // Frontmatter
  lines.push('---');
  lines.push(`title: ${displayName}`);
  lines.push(`description: ${doc.description || doc.ddocComment || `The ${displayName} assertion`}`);
  lines.push('---');
  lines.push('');

  // Title
  lines.push(`# .${displayName}()`);
  lines.push('');

  // Description
  if (doc.description) {
    lines.push(doc.description);
    lines.push('');
  }
  if (doc.ddocComment && doc.ddocComment !== doc.description) {
    lines.push(doc.ddocComment);
    lines.push('');
  }

  // Examples section
  if (doc.examples.length > 0) {
    lines.push('## Examples');
    lines.push('');

    // Success examples
    const successExamples = doc.examples.filter(e => !e.isFailure && !e.isNegation);
    if (successExamples.length > 0) {
      lines.push('### Basic Usage');
      lines.push('');
      lines.push('```d');
      for (const ex of successExamples.slice(0, 3)) {
        lines.push(ex.code);
      }
      lines.push('```');
      lines.push('');
    }

    // Negation examples
    const negationExamples = doc.examples.filter(e => e.isNegation && !e.isFailure);
    if (negationExamples.length > 0) {
      lines.push('### With Negation');
      lines.push('');
      lines.push('```d');
      for (const ex of negationExamples.slice(0, 2)) {
        lines.push(ex.code);
      }
      lines.push('```');
      lines.push('');
    }

    // Failure examples (for understanding error messages)
    const failureExamples = doc.examples.filter(e => e.isFailure);
    if (failureExamples.length > 0) {
      lines.push('### What Failures Look Like');
      lines.push('');
      lines.push('When the assertion fails, you\'ll see a clear error message:');
      lines.push('');
      lines.push('```d');
      lines.push(`// This would fail:`);
      lines.push(failureExamples[0].code);
      lines.push('```');
      lines.push('');
    }
  }

  // Supported types
  if (doc.supportedTypes.length > 0) {
    lines.push('## Supported Types');
    lines.push('');
    for (const type of doc.supportedTypes) {
      lines.push(`- \`${type}\``);
    }
    lines.push('');
  }

  // Aliases
  if (doc.aliases.length > 0) {
    lines.push('## Aliases');
    lines.push('');
    for (const alias of doc.aliases) {
      lines.push(`- \`.${alias}()\``);
    }
    lines.push('');
  }

  // Modifiers
  if (doc.hasNegation) {
    lines.push('## Modifiers');
    lines.push('');
    lines.push('This assertion supports the following modifiers:');
    lines.push('');
    lines.push('- `.not` - Negates the assertion');
    lines.push('- `.to` - Language chain (no effect)');
    lines.push('- `.be` - Language chain (no effect)');
    lines.push('');
  }

  return lines.join('\n');
}

/**
 * Recursively find all .d files in a directory
 */
function findDFiles(dir) {
  const files = [];

  if (!existsSync(dir)) {
    return files;
  }

  const entries = readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...findDFiles(fullPath));
    } else if (entry.name.endsWith('.d') && !['package.d', 'registry.d'].includes(entry.name)) {
      files.push(fullPath);
    }
  }
  return files;
}

/**
 * Main execution
 */
function main() {
  console.log('Extracting documentation from D source files...');
  console.log(`Source: ${sourceRoot}`);
  console.log(`Output: ${outputRoot}`);

  // Find all D files
  const dFiles = findDFiles(sourceRoot);
  console.log(`Found ${dFiles.length} D source files`);

  // Process each file
  const docs = [];
  for (const file of dFiles) {
    try {
      const doc = parseSourceFile(file);
      // Include if has description, examples, or is a valid operation function
      if (doc.description || doc.ddocComment || doc.examples.length > 0 || doc.functionName) {
        docs.push(doc);
        console.log(`  Parsed: ${doc.name}${doc.functionName ? ` (${doc.functionName})` : ''}`);
      }
    } catch (err) {
      console.warn(`  Warning: Could not parse ${file}: ${err.message}`);
    }
  }

  // Generate markdown files
  for (const doc of docs) {
    const category = getCategoryFromPath(doc.filePath);
    const categoryDir = join(outputRoot, category);

    mkdirSync(categoryDir, { recursive: true });

    const markdown = generateMarkdown(doc);
    const outputPath = join(categoryDir, `${doc.name}.mdx`);

    writeFileSync(outputPath, markdown);
    console.log(`  Generated: ${outputPath}`);
  }

  console.log(`\nGenerated ${docs.length} documentation files`);
}

main();
