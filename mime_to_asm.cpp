#include <iostream>
#include <fstream>
#include <string>
#include <map>
#include <cstdint>
#include "nlohmann/json.hpp"

using json = nlohmann::json;

std::stringstream asm_output("");

int main(){
    std::ifstream mime_json("mime_map.json");
    std::ofstream mime_table_out("mime_table.inc");
    std::unordered_map<std::string, std::string> data = json::parse(mime_json);

    for (auto [key, value] : data){
        asm_output << key.substr(1) << " db \"" << key << '\"' << '\n';
        asm_output << key.substr(1) << "_type" << " db \"" << value << '\"' << '\n';
    }

    asm_output << '\n' << "mime_table:" << '\n';

    for (auto [key, value] : data){
        asm_output << '\t' << "istruc Extension_link" << '\n';
        asm_output << "\t\t" << "at extension, dq " << key.substr(1) << " dq " << key.length() << '\n';
        asm_output << "\t\t" << "at content_type, dq " << key.substr(1) << "_type" << " dq " << value.length() << '\n';
        asm_output << '\t' <<"iend" << '\n';
    }


    mime_table_out << asm_output.str() << '\n';
    
    return 0;
}