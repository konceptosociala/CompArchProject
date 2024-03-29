# CompArchProject

This program reads strings from input, processes them, and prints the occurrences of a specific substring within each string along with their indices. It also sorts the occurrences based on the occurances amount

## Usage
```powershell
> MAIN ab <test.in
```
test.in:
```
babbabbbab
abbaabaabaaabaaaa
aaaaab aaa bab
abbaabaabaaabaaaaababababb
sab
```
Output:
```
1 4
2 2
3 0
4 1
8 3

```

## Features
- Reads strings from `stdin` and parses 1st parameter as a substring.
- Identifies occurrences of a specified substring within each string.
- Counts and prints the number of occurrences along with their indices.
- Sorts the occurrences based on the occurances amount.

## Requirements
- DOS environment or DOS emulator.

## Limitations
- Limited to ASCII character set.
- Maximum string size is 255 characters.
- Assumes input strings are terminated with ASCII carriage return or line feed.
- Sorting is done in ascending order only

## License
This program is licensed under Unlicense license

