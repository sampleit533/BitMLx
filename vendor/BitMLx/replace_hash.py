"""Replace placeholder strings in BitML/Racket output files with hashed random strings.

Usage:
      python3 replace_hash.py [--seed SEED] <./output/filename>

When ``--seed`` is supplied (or the ``BITMLX_HASH_SEED`` environment variable
is set), the random number generator is reseeded before processing the file,
making the generated hashes deterministic across runs. This produces
byte-identical artifacts for reviewer-side verification, while the default
unseeded behaviour preserves the original random-hash semantics.
"""

import argparse
import os
import random
import re
import string
import sys
from hashlib import sha256


def in_file_replace(filepath, hash_placeholders_list=None):
  """Replace specified placeholders in a file.

  Args:
      filepath (str): The path of the file (under ./output) to modify.
      hash_placeholders_list (list, optional): A list of placeholders to
          be replaced. Defaults to ["__HASH__PLACEHOLDER__", "__SOME_HASH__"].

  Raises:
      FileNotFoundError: If the specified file is not found.
  """
  if hash_placeholders_list is None:
    hash_placeholders_list = ["__HASH__PLACEHOLDER__", "__SOME_HASH__"]
  try:
    with open(filepath, "r") as f:
      racket_code = f.read()

    modified_code = replace_strings(racket_code, hash_placeholders_list)

    with open(filepath, "w") as f:
      f.write(modified_code)

    print(f"Successfully modified strings in '{filepath}'.")

  except FileNotFoundError:
    print(f"Error: File '{filepath}' not found.")


def replace_strings(racket_code, placeholders):
  """Replaces specified placeholders in a string of Racket code with hashed random strings."""
  result = ""
  for line in racket_code.splitlines():
    for p in placeholders:
      matches = re.findall(p, line)
      for match in matches:
        random_string = generate_random_string()
        hash_string = sha256(random_string.encode('utf-8')).hexdigest()
        line = line.replace(p, hash_string)

    result += line + "\n"
  return result


def generate_random_string(result_length=30):
  """Generates a random string of the specified length."""
  sample_alphabet = string.ascii_letters + string.digits + '!@#$%^&*()-+=.'
  return ''.join(random.sample(sample_alphabet, result_length))


def _resolve_seed(cli_seed):
  """Pick a seed value from the CLI flag or the BITMLX_HASH_SEED env var, in that order."""
  if cli_seed is not None:
    return cli_seed
  env_seed = os.environ.get("BITMLX_HASH_SEED")
  if env_seed:
    return env_seed
  return None


def _apply_seed(seed):
  if seed is None:
    return
  try:
    random.seed(int(seed))
  except (TypeError, ValueError):
    random.seed(seed)


if __name__ == "__main__":
  parser = argparse.ArgumentParser(
      description="Replace hash placeholders in a BitML/Racket output file. "
                  "Pass --seed (or set BITMLX_HASH_SEED) to obtain "
                  "byte-deterministic artifacts.")
  parser.add_argument("filepath",
                      help="Path to the .rkt file to rewrite in place.")
  parser.add_argument("--seed", default=None,
                      help="Optional integer or string seed for the random "
                           "generator. When omitted, falls back to the "
                           "BITMLX_HASH_SEED environment variable; when both "
                           "are unset, hashes are fresh on every run.")
  args = parser.parse_args()

  _apply_seed(_resolve_seed(args.seed))
  in_file_replace(args.filepath)
