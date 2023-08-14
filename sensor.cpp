#include "batypes/sensor.h"

#include <math.h>

using Json = nlohmann::json;

using namespace batypes;


// --------------------------------    struct Sensor

/// @brief Дефолтный конструктор

Sensor::Sensor()
    : name("")
    , fname("")
    , extraCmdScript("")
    , comment("")
    , swithSensorName("")
    , flagUsingSwitch(false)
    , flagSensorOn(false)
    , sensorLength(0.0)
    , sensorPointLength(0)
    , centralFreq(0.0)
    , freqStart(0.0)
    , freqStop(0.0)
    , freqStep(0.0)
    , Average(0)
    , pulseLength(30)
    , pulseGain(15000)
    , cwAtt(15000)
    , apdGain(14500)
{ }
/////////////////////////////////////////////////////
/// @brief Конструктор по имени сенсора
/// @param name  имя сенсора

Sensor::Sensor(std::string name)
{
	this->name = name;
	Sensor();
}
////////////////////////////////////////////////////
/// @brief деструктор

Sensor::~Sensor() {}

///////////////////////////////////////////////////////
/// @brief Сравнение compName с коротким именем сенсора
/// @param compName  - это compName
/// @return true - если совпадает, false - если не совпадает

bool Sensor::chekName(const std::string compName) {
	return(name == compName);
}

// -----------------------------------  struct SensorsList

SensorsList::SensorsList() : snrList({}),curSensor(-1){} //внимание !!! при пустом списке равен -1
// ----------------------------- XML ---------------------------------------
// создает DOM Xml на основе sensorsList и сохраняет в файл
// bool SensorsList::sensorsListToXmlFile(const char *xmlFileName){

// 	TiXmlDocument sensorConf;              // создаем пустой документ

// 	TiXmlDeclaration * decl = new TiXmlDeclaration("1.0", "UTF - 8", "yes");	// создаем декларацию документа
// 	TiXmlElement * sensors = new TiXmlElement("Channals");						// создаем root элемент документа
// 	//TiXmlText * text = new TiXmlText("World");
// 	//element->LinkEndChild(text);
// 	sensorConf.LinkEndChild(decl);												// подсоединяем декларацию к документу
// 	sensorConf.LinkEndChild(sensors);											// подсоединяем root элемент к документу

// 	for (auto& snr : snrList) {													// итерируемя по списку сенсоров
// 		TiXmlElement * snrXml = new TiXmlElement(snr.name.c_str());
// 		snrXml->SetAttribute("fname", snr.fname.c_str());
// 		snrXml->SetAttribute("extraCmdScript", snr.extraCmdScript.c_str());
// 		snrXml->SetAttribute("comment", snr.comment.c_str());
// 		sensors->LinkEndChild(snrXml);											// создаем узел сенсора
// 	}

// 	return sensorConf.SaveFile(xmlFileName);
// }

// // запоняет  sensorsList на основе файла xml
// bool SensorsList::xmlFileToSensorsList(const char *xmlFileName){

// 	TiXmlDocument sensorConf;

// 	if (!sensorConf.LoadFile(xmlFileName))
// 		return false;

// 	TiXmlElement * sensors = sensorConf.RootElement();
// 	TiXmlHandle root(0);

// 	root = TiXmlHandle(sensors);

// 	TiXmlElement *sensor;
// 	sensor = root.FirstChild().Element();

// 	//testmsg(sensor->Value());
// 	while (sensor){
// 		Sensor snr = {};
// 		snr.name = std::string(sensor->Value());
// 		snr.fname = std::string(sensor->Attribute("fname"));
// 		snr.extraCmdScript = std::string(sensor->Attribute("extraCmdScript"));
// 		snr.comment = std::string(sensor->Attribute("comment"));

// 		this->addSensor(snr);
// 		sensor = sensor->NextSiblingElement();

// 	}

// 	return true;
// }
// ------------------------------------- JSON ----------------------------------------------------

Json sensorToJson(Sensor& snr)
{

	Json snrObj;

	snrObj["name"] =  snr.name;
	snrObj["fname"] =  snr.fname;
	snrObj["extraCmdScript"] = snr.extraCmdScript;
	snrObj["comment"] = snr.comment;
	snrObj["swithSensorName"] = snr.swithSensorName;
	snrObj["flagUsingSwitch"] = snr.flagUsingSwitch;
	snrObj["flagSensorOn"] = snr.flagSensorOn;
    snrObj["sensorLength"] =  snr.sensorLength;
    snrObj["sensorPointLength"] = snr.sensorPointLength;
	snrObj["centralFreq"] = (float)(round((double)(snr.centralFreq) * 100000) / 100000);
 	snrObj["freqStart"] = float(round((double)(snr.freqStart) * 100000) / 100000);
	snrObj["freqStop"] = (float)(round((double)(snr.freqStop) * 100000) / 100000);
 	snrObj["freqStep"] =(float)(round((double)(snr.freqStep) * 100000) / 100000);
    snrObj["Average"] = snr.Average;

	snrObj["pulseLength"] = snr.pulseLength;
	snrObj["pulseGain"] = snr.pulseGain;
	snrObj["cwAtt"] = snr.cwAtt;
	snrObj["apdGain"] = snr.apdGain;

	return snrObj;
}

// сохраняет в Json файл
bool SensorsList::sensorsListToJsonFile(const char* JsonFileName) {

	Json sensorsObj;						// создаем root элемент документа

    std::cout << "write file: " << JsonFileName << std::endl;
	for (auto& snr : snrList) {												// итерируемя по списку сенсоров
				sensorsObj["Sensors"][snr.name]=sensorToJson(snr);

	}

	std::ofstream fs;
	fs.open(JsonFileName,std::ios::trunc);
	if(!fs.is_open()) {
		std::cout << "Error create json file: " << JsonFileName << std::endl;
		return false;
	}

	// !!!! тут обработать ошибку записи в файл

	fs << sensorsObj.dump(4) << std::endl;
	std::cout << sensorsObj.dump(4) << std::endl;

	fs.close();

	return true;

}

bool SensorsList::sensorsListToScript(std::string scriptPath) {

	for (auto& snr : snrList) {													// итерируемя по списку сенсоров
		std::fstream ff;
		std::string fName = scriptPath+"set_"+snr.name+".sc";
		ff.open(fName,std::ios::out | std::ios::trunc);
		if(ff.is_open()) {
			ff << "cmd delay 1000" << "\n";
			ff<<"########## start #############" << "\n";
			ff<<"########## "<<snr.name << " ###########" << "\n";
			ff<<"cmd Files DataPath ../ba_data/"+snr.name << "\n";
			ff<<"cmd core DataSize "<<snr.sensorPointLength << "\n";
			ff<<"cmd math DataEnd  " <<snr.sensorPointLength-100 << "\n";
			ff<<"cmd math SmoothPoint " << snr.sensorPointLength -70  << "\n";
			ff<<"##############################" << "\n";
			ff<<"cmd delay 1000" << "\n";
			ff<<"cmd math DataStart " << "890\n";
			ff<<"##############################" << "\n";
			ff<<"cmd core Average " << snr.Average << "\n";

			ff<<"cmd mod Time2 " << snr.pulseLength / 5 << "\n";
			ff<<"cmd term PumpCurrent " << snr.pulseGain << "\n";
			ff<<"cmd term VOA " << snr.cwAtt << "\n";
			ff<<"cmd term APDVoltage " << snr.apdGain << "\n";

			ff<<"####### End #################" << "\n";
			ff.close();
			std::cout  << "Created: " << fName << std::endl;
		} else {
			std::cout  << "Don't create: " << fName << std::endl;
			return false;
		}
	}
	return true;
}


// заполняет  sensorsList на основе файла Json
bool SensorsList::JsonFileToSensorsList(const char* JsonFileName) {

	Json snrConf;              // создаем пустой документ

     std::cout << "read file: " << JsonFileName << std::endl;
	std::ifstream fs;
	fs.open(JsonFileName);
    if(!(fs.is_open())) {
        std::cout << "Don't open: " << JsonFileName << std::endl;
        return false;
    }

	try {
		snrConf = Json::parse(fs);
	}
	catch (Json::parse_error& ex) {
		std::cout << "parse jsonFile: " << JsonFileName << "Error byte " << ex.byte << std::endl;
		return false;
	}
	if(snrConf["Sensors"].is_null()) {
		std::cout << "Don't jbject Sensors" << std::endl;
		return false;
	}

	for (auto& jsnr : snrConf["Sensors"]) {

		Sensor snr = {};
		snr.name = jsnr.value("name","sensor"); 								//	короткое имя сенсора
		snr.fname = jsnr.value("fname","sensor"); 					//полное имя сенсора
		snr.extraCmdScript = jsnr.value("extraCmdScript",""); //скрипт для установки дополнительных параметров сенсора
		snr.comment = jsnr.value("comment","");
		snr.swithSensorName = jsnr.value("swithSensorName","");
		snr.flagUsingSwitch = jsnr.value<bool>("flagUsingSwitch",0);
		snr.flagSensorOn = jsnr.value<bool>("flagSensorOn",0);
		snr.sensorLength = jsnr.value<float>("sensorLength",0);
        snr.sensorPointLength = jsnr.value<int>("sensorPointLength",0); // длина сенсора в точеках
		snr.centralFreq = jsnr.value<float>("centralFreq",0);       // основная частота
		snr.freqStart = jsnr.value<float>("freqStart",0);		// начальная частота SWEEP
		snr.freqStop = jsnr.value<float>("freqStop",0);			// конечная частота SWEEP
		snr.freqStep = jsnr.value<float>("freqStep",1);			// шаг частоты SWEEP
		snr.Average = jsnr.value<int>("Average",1);			// колличество усреднений

		snr.pulseLength = jsnr.value<int>("pulseLength",1);
		snr.pulseGain = jsnr.value<int>("pulseGain",1);
		snr.cwAtt = jsnr.value<int>("cwAtt",1);
		snr.apdGain = jsnr.value<int>("apdGain",1);

		std::cout << snr.name << std::endl;
		std::cout << snr.fname << std::endl;
		std::cout << snr.extraCmdScript << std::endl;
		std::cout << snr.comment << std::endl;
		std::cout << snr.sensorLength << " " << jsnr.value<float>("sensorLength",0) << std::endl;



		this->addSensor(snr);
	}



	return true;
}


// добавляет сенсор в конец списка
void SensorsList::addSensor(Sensor snr) {
	snrList.push_back(snr);
}

// добавляет пустой сенсор заданный коротким именем в конец списка
void SensorsList::addSensorByName(const char* snrName) {
	Sensor snr;
	snr.name = std::string(snrName);
	snrList.push_back(snr);
}

SensorsList::~SensorsList(){}

