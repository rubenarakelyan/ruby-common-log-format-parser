# Ruby Common Log Format Parser

This is a hacky script that parses a log file in the Common Log Format and tests what HTTP status a lowercase version of each requested URL returns as compared to the original request. It was written to allow analysis of the impact of moving GOV.UK from case-sensitive to case-insensitive routing of requests.
