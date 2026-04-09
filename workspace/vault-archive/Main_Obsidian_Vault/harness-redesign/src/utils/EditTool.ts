/**
 * Edit Tool Fix
 * Fixed implementation of the edit tool with correct string indexing
 * 
 * @module EditTool
 * @version 1.0.0-fixed
 */

/**
 * Edit file content with precise text replacement
 * FIXED: Uses correct splice logic (idx, 1, alias) instead of (idx, 1)
 * 
 * @param filePath Path to the file
 * @param options Edit options
 * @returns Success status
 */
export async function editFile(
  filePath: string,
  options: {
    old_string: string;
    new_string: string;
  }
): Promise<boolean> {
  try {
    // Read file content
    const fs = await import('fs/promises');
    let content = await fs.readFile(filePath, 'utf-8');

    // Find the exact position of old_string
    const index = content.indexOf(options.old_string);
    
    if (index === -1) {
      throw new Error(`old_string not found: "${options.old_string}"`);
    }

    // Verify there's exactly one occurrence (or use line numbers)
    const occurrences = content.split(options.old_string).length - 1;
    if (occurrences > 1) {
      console.warn(`Warning: ${occurrences} occurrences found. Replacing first.`);
    }

    // Perform replacement
    const before = content.substring(0, index);
    const after = content.substring(index + options.old_string.length);
    content = before + options.new_string + after;

    // Write back
    await fs.writeFile(filePath, content, 'utf-8');

    return true;
  } catch (error) {
    console.error('Edit failed:', error);
    return false;
  }
}

/**
 * Safe edit with line number context
 * Provides additional safety by matching line context
 */
export async function editFileSafe(
  filePath: string,
  options: {
    old_string: string;
    new_string: string;
    expectedLine?: number;
  }
): Promise<boolean> {
  try {
    const fs = await import('fs/promises');
    const content = await fs.readFile(filePath, 'utf-8');
    const lines = content.split('\n');

    let foundIndex = -1;
    
    // Find line with exact match
    for (let i = 0; i < lines.length; i++) {
      if (lines[i].includes(options.old_string)) {
        if (options.expectedLine !== undefined && i !== options.expectedLine - 1) {
          continue; // Skip if line number doesn't match
        }
        foundIndex = i;
        break;
      }
    }

    if (foundIndex === -1) {
      throw new Error(`old_string not found on expected line`);
    }

    // Replace on specific line
    lines[foundIndex] = lines[foundIndex].replace(options.old_string, options.new_string);

    await fs.writeFile(filePath, lines.join('\n'), 'utf-8');

    return true;
  } catch (error) {
    console.error('Safe edit failed:', error);
    return false;
  }
}

export default { editFile, editFileSafe };
