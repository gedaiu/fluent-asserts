#!/usr/bin/env node
/**
 * Updates the version information in the documentation.
 * Reads the latest git tag and writes to src/content/version.json
 */

import { execSync } from 'child_process';
import { writeFileSync, readFileSync, mkdirSync } from 'fs';
import { dirname, join } from 'path';
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

const version = getLatestVersion();
const { commitHash, commitDate } = getGitInfo();

const versionInfo = {
  version,
  commitHash,
  commitDate,
  generatedAt: new Date().toISOString(),
};

// Write version.json to public directory (static assets)
const outputPath = join(docsRoot, 'public', 'version.json');
mkdirSync(dirname(outputPath), { recursive: true });
writeFileSync(outputPath, JSON.stringify(versionInfo, null, 2));

// Update version in index.mdx tagline
const indexPath = join(docsRoot, 'src', 'content', 'docs', 'index.mdx');
try {
  let indexContent = readFileSync(indexPath, 'utf-8');
  // Update the version in the tagline
  indexContent = indexContent.replace(
    /Current version v[\d.]+/,
    `Current version v${version}`
  );
  writeFileSync(indexPath, indexContent);
  console.log(`Updated index.mdx tagline to v${version}`);
} catch (err) {
  console.warn('Could not update index.mdx:', err.message);
}

console.log(`Version info updated: v${version} (${commitHash})`);
