#include <iostream>
#include <fstream>
#include <string>
#include <map>
#include <cstdint>
#include <utility>
#include "nlohmann/json.hpp"

using json = nlohmann::json;

std::stringstream asm_output("");

std::pair<std::string, std::string> safeguard_key(const std::string& key){
    std::string key_safeguarded = key.substr(1);
    std::replace(key_safeguarded.begin(), key_safeguarded.end(), '-', '_');
    std::string key_label = "ext_" + key_safeguarded;
    std::string value_label = "type_" + key_safeguarded;
    return std::pair<std::string, std::string>(key_label, value_label);
}

int main(){
    std::ifstream mime_json("mime_map.json");
    std::ofstream mime_table_out("mime_table.inc");
    std::map<std::string, std::string> data = json::parse(mime_json);

    for (auto [key, value] : data){
        auto [key_label, value_label] = safeguard_key(key);

        asm_output << key_label << " db \"" << key << '\"' << '\n';
        asm_output << value_label << " db \"" << value << '\"' << '\n';
    }

    asm_output << '\n' << "mime_table:" << '\n';

    for (auto [key, value] : data){
        auto [key_label, value_label] = safeguard_key(key);
        asm_output << '\t' << "istruc Extension_link" << '\n';
        asm_output << "\t\t" << "at .extension, dq " << key_label << ", " << key.length() << '\n';
        asm_output << "\t\t" << "at .content_type, dq " << value_label << ", " << value.length() << '\n';
        asm_output << '\t' <<"iend" << '\n';
    }

    mime_table_out << asm_output.str() << '\n';
    
    return 0;
}