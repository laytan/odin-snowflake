# Odin snowflake

Snowflake ID's are a form of unique identifiers developed originally by/for Twitter.
ID's are sortable (by creation time), store the generation time in them (no need for a created_at field in a DB),
are a length of 13 bytes in base32 and 100% unique if used correctly.
Learn more here: [https://en.wikipedia.org/wiki/Snowflake_ID](https://en.wikipedia.org/wiki/Snowflake_ID).
