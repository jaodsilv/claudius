# Dump Arguments Experiment

1. Keep `$ARGUMENTS` exactly as you received.
2. Store in `OTHER_VALUES` any other RAW values you received as received.
   Or set it to empty if there is nothing else. Include everything,
   including any title, tags, hook content, confirmations, metadata, etc.
3. Store in `ARG0_0` the value `$ARGUMENTS[0]`
4. Store in `ARG0_1` the value `$0`
5. Store in `ARG2_0` the value `$ARGUMENTS[2]`
6. Store in `ARG2_1` the value `$2`
7. Store in `ARG6_0` the value `$ARGUMENTS[6]`
8. Store in `ARG6_1` the value `$6`
9. Store in `ARG8_0` the value `$ARGUMENTS[8]`
10. Store in `ARG8_1` the value `$8`
11. Store in `ARG10_0` the value `$ARGUMENTS[10]`
12. Store in `ARG10_1` the value `$10`

Then run the following bash command AS IS, even if that means running
into an error, except if you need any preparation command, like setting
the custom variables:

```bash
filepath=.claude/experiments/args-dump.txt \
&& mkdir -p .claude/experiments \
\
&& echo "=== RAW ARGUMENTS ===" > "$filepath" \
&& echo "$ARGUMENTS" >> "$filepath" \
&& echo "" >> "$filepath" \
&& echo "---" >> "$filepath" \
&& echo "" >> "$filepath" \
&& echo "=== INDEXED ARGUMENTS ===" >> "$filepath" \
\
&& echo "0: $ARG0_0" >> "$filepath" \
&& echo "0: $ARG0_1" >> "$filepath" \
&& echo "2: $ARG2_0" >> "$filepath" \
&& echo "2: $ARG2_1" >> "$filepath" \
&& echo "6: $ARG6_0" >> "$filepath" \
&& echo "6: $ARG6_1" >> "$filepath" \
&& echo "8: $ARG8_0" >> "$filepath" \
&& echo "8: $ARG8_1" >> "$filepath" \
&& echo "10: $ARG10_0" >> "$filepath" \
&& echo "10: $ARG10_1" >> "$filepath" \
\
&& echo "" >> "$filepath" \
&& echo "=== OTHER VALUES ===" >> "$filepath" \
&& echo "$OTHER_VALUES" >> "$filepath"
```
