#!/usr/bin/env node
/**
 * Updates the version information in the documentation.
 * Reads the latest git tag and writes to src/content/version.json
 * Also updates version references in all markdown files.
 */

import { execSync } from 'child_process';
import { writeFileSync, readFileSync, mkdirSync, readdirSync, statSync } from 'fs';
import { dirname, join, extname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const docsRoot = join(__dirname, '..');

function getLatestVersion() {
  try {
    // Try to get the latest tag
    const tag = execSync('git describe --tags --abbrev=0 2>/dev/null', {
      encoding: 'utf-8',
      cwd: join(docsRoot, '..'),
    }).trim();
    return tag.replace(/^v/, ''); // Remove 'v' prefix if present
  } catch {
    try {
      // Fallback: get the last tag from list
      const tags = execSync('git tag -l', {
        encoding: 'utf-8',
        cwd: join(docsRoot, '..'),
      }).trim();
      const tagList = tags.split('\n').filter(t => t);
      if (tagList.length > 0) {
        return tagList[tagList.length - 1].replace(/^v/, '');
      }
    } catch {
      // Ignore
    }
    return '0.0.0';
  }
}

function getGitInfo() {
  let commitHash = 'unknown';
  let commitDate = new Date().toISOString();

  try {
    commitHash = execSync('git rev-parse --short HEAD', {
      encoding: 'utf-8',
      cwd: join(docsRoot, '..'),
    }).trim();
  } catch {
    // Ignore
  }

  try {
    commitDate = execSync('git log -1 --format=%cI', {
      encoding: 'utf-8',
      cwd: join(docsRoot, '..'),
    }).trim();
  } catch {
    // Ignore
  }

  return { commitHash, commitDate };
}

/**
 * Recursively find all markdown files in a directory
 */
function findMarkdownFiles(dir, files = []) {
  const entries = readdirSync(dir);
  for (const entry of entries) {
    const fullPath = join(dir, entry);
    const stat = statSync(fullPath);
    if (stat.isDirectory()) {
      findMarkdownFiles(fullPath, files);
    } else if (['.md', '.mdx'].includes(extname(entry))) {
      files.push(fullPath);
    }
  }
  return files;
}

/**
 * Get the major.minor version for DUB dependency format (e.g., "2.0" from "2.0.0-beta.1")
 */
function getMajorMinorVersion(version) {
  const match = version.match(/^(\d+\.\d+)/);
  return match ? match[1] : version;
}

const version = getLatestVersion();
const majorMinor = getMajorMinorVersion(version);
const { commitHash, commitDate } = getGitInfo();

const versionInfo = {
  version,
  majorMinor,
  commitHash,
  commitDate,
  generatedAt: new Date().toISOString(),
};

// Write version.json to public directory (static assets)
const outputPath = join(docsRoot, 'public', 'version.json');
mkdirSync(dirname(outputPath), { recursive: true });
writeFileSync(outputPath, JSON.stringify(versionInfo, null, 2));

// Find all markdown files in the docs
const contentDir = join(docsRoot, 'src', 'content', 'docs');
const markdownFiles = findMarkdownFiles(contentDir);

let updatedFiles = 0;

for (const filePath of markdownFiles) {
  try {
    let content = readFileSync(filePath, 'utf-8');
    let modified = false;
    const originalContent = content;

    // Update "Current version vX.X.X" pattern (index.mdx tagline)
    // Match full semver including optional prerelease suffix like -beta.1
    content = content.replace(
      /Current version v[\d]+\.[\d]+\.[\d]+([-\w.]*)?/g,
      `Current version v${version}`
    );

    // Update DUB SDL dependency version: version="~>X.X"
    content = content.replace(
      /version="~>[\d.]+"/g,
      `version="~>${majorMinor}"`
    );

    // Update DUB JSON dependency version: "~>X.X"
    content = content.replace(
      /"fluent-asserts":\s*"~>[\d.]+"/g,
      `"fluent-asserts": "~>${majorMinor}"`
    );

    if (content !== originalContent) {
      writeFileSync(filePath, content);
      modified = true;
      updatedFiles++;
      console.log(`Updated: ${filePath.replace(docsRoot, '')}`);
    }
  } catch (err) {
    console.warn(`Could not update ${filePath}:`, err.message);
  }
}

console.log(`\nVersion info updated: v${version} (${commitHash})`);
console.log(`Updated ${updatedFiles} markdown file(s)`);
