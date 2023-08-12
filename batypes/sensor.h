#pragma once


#include <string>
#include <iostream>
#include <fstream>
#include <vector>
#include "tinyxml.h"
#include <nlohmann/json.hpp>


namespace batypes {

/// @brief класс описания сенсора / конфигурация
//
struct Zone;
struct SensorLine;

struct Sensor
{

	std::string name;				///< короткое имя сенсора
	std::string fname;				///< полное имя сенсора
	std::string extraCmdScript;		///< скрипт для установки дополнительных параметров сенсора
	std::string comment;			///< комментарий
	std::string swithSensorName; 	///< имя сенсора на свитче

	bool  flagUsingSwitch;           ///< bool - используется свитч при включении канала
	bool  flagSensorOn;              ///< bool - сенсор включен

    float 			sensorLength;    	///< длина сенсора в метрах
	int   			sensorPointLength; 	///< длина сенсора в дискретах
	float 			centralFreq;      	///< основная частота
	float 			freqStart;			///< начальная частота SWEEP
	float 			freqStop;			///< конечная частота SWEEP
	float 			freqStep;			///< шаг частоты SWEEP
	int   			Average;			///< колличество усреднений
	unsigned int 	pulseLength;     	///< длина импульса (влияет на разрешение прибора)
	unsigned int  	pulseGain;			///< величина импульса импульса
	unsigned int  	cwAtt;              ///< величина постоянной составляющей
	unsigned int  	apdGain;            ///< что-то с лавинным диодом, влияет на CW тоже (иногда надо уменьшать)

	Sensor();

	Sensor(std::string name);

	bool chekName(const std::string compName); ///< сравнение имени сенсора

	~Sensor();
};

struct PreparedSensorToQuery
{

	std::string name;				///< короткое имя сенсора
	std::string fname;				///< полное имя сенсора
	std::string extraCmdScript;		///< скрипт для установки дополнительных параметров сенсора
	std::string comment;			///< комментарий
	std::string swithSensorName; 	///< имя сенсора на свитче

	std::string flagUsingSwitch;           ///< bool - используется свитч при включении канала
	std::string flagSensorOn;              ///< bool - сенсор включен

    std::string sensorLength;    	///< длина сенсора в метрах
	std::string sensorPointLength; 	///< длина сенсора в дискретах
	std::string centralFreq;      	///< основная частота
	std::string freqStart;			///< начальная частота SWEEP
	std::string freqStop;			///< конечная частота SWEEP
	std::string freqStep;			///< шаг частоты SWEEP
	std::string Average;			///< колличество усреднений
	std::string pulseLength;     	///< длина импульса (влияет на разрешение прибора)
	std::string pulseGain;			///< величина импульса импульса
	std::string cwAtt;              ///< величина постоянной составляющей
	std::string apdGain;            ///< что-то с лавинным диодом, влияет на CW тоже (иногда надо уменьшать)
};

struct SensorsList
{

	std::vector < Sensor > snrList;		// вектор сенсоров
	int curSensor;							// номер текущего сенсора

	SensorsList();

	//bool sensorsListToXmlFile(const char* xmlFileName);  // создает xmlFile на основе SensorsList
	bool sensorsListToJsonFile(const char* JsonFileName);  // создает jsonFile на основе SensorsList
	bool sensorsListToScript(std::string scriptPath);  // создает jsonFile на основе SensorsList

	//bool xmlFileToSensorsList(const char* xmlFileName);   // запоняет  sensorsList на основе xmlFile
	bool JsonFileToSensorsList(const char* JsonFileName);   // запоняет  sensorsList на основе xmlFile


	void addSensor(Sensor snr);						// добавляет сенсор в конец списка
	void addSensorByName(const char* snrName);		// добавляет сенсор в конец списка поимени

	~SensorsList();
};

struct SensorDB : public Sensor
{
    int sensorId;
    std::vector <SensorLine>  snrLines;
    std::vector <Zone>  snrZones;
};
}
