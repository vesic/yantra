require "./translate"

# Translate.new.produce('en.txt', 'out.txt', 'de')
Translate.new.merge_files ['in.txt', 'in.txt', 'in.txt'], './hello.txt'