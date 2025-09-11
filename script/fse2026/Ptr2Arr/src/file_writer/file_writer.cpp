#include "../../include/file_writer/file_writer.h"
#include <string.h>

void WriteToFile(const std::string& content) {
    const std::string outPath = outputDirectory / (sourceCodeName + "_Metadata_Ptr2Arr.txt");
    std::ofstream outFile(outPath, std::ios::app);
    if (!outFile) {
        std::cerr << strerror(errno) << ": " << outPath << std::endl;
        return;
    }
    outFile << content << std::endl;
    outFile.close();
}