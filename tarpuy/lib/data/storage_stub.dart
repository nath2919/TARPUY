final _memory = <String, String>{};
String? readLocal(String key) => _memory[key];
void writeLocal(String key, String value) => _memory[key] = value;
void removeLocal(String key) { _memory.remove(key); }
