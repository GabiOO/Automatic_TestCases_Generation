/*
* File: Test_Creator.cpp
* Author: Gabriel Olea Olea
*/

#include <iostream>
#include <fstream>
#include <vector>
#include <regex> 
#include <assert.h>
using namespace std;

//---Global variables
string function_name, return_type, param_name, param_type; //Information gathered later in the first part of the main function
vector<string> param_names, param_types;
vector<string> params_type_treatment;
string return_type_treatment;
bool many_params;            //Are there more than 1 parameter?

bool array_support = false;  //Array support
bool int_support = false;    //Needed if a value is equal to MaxInt or MinInt
string MaxInt = "2147483647", MinInt = "-2147483648";

bool old_attribute_support = false; //Needed to simulate the 'Old attribute outside the postcondition assertion
string old_attribute_simulation;

bool verbose = false; //If true, cout will be used to show info via screen


//*************  Auxiliary Functions *******************************

//Functions to ensure a good parameter treatment
void Int_Param_Treatment ( string & param );

void Real_Param_Treatment ( string & param );

/*
  Behaviour expression translator:
  If there is only one parameter, we replace its name for "Test_Vector"
  If there are more, we replace them for "Test_Vector.<param_name>"
  E.g: Invariant( M + 1, New_Speed ) => Invariant( Test_Vector.M + 1, Test_Vector.New_Speed )
  Note that it is VERY IMPORTANT that parameters appear separated by blank spaces for this regex to work
  or a white space on the left and a ",", "(" , or end of line ($) on the right 
*/
void Translate_Behaviour_Expression( string & behaviour_expression );



//****************************************  Main function  ******************************************
int main(int argc, char *argv[]){

	//Mimimal check and help for the user
	if ( argc != 3 ){ 
		cerr << "Usage: ./Ada_Test_Creator <target_function>-IsolatedInfo.txt <target_function>-RawTests.txt" <<endl;
		exit(1);
	}
	
	ifstream inData;  //IN file stream
	
   	//*******************************************************************************************
   	//First part, reding data from the isolated information document
   	string junk;                              //String used to store junk text
	char junk_char;                           //Char used for reading commas, parenthesis, etc
   	string line, word;                        //Strings used to manage text
   	
	const string isoInfoFile_name = argv[1];  //Isolated-Info file name
	string spec_file_name;                    //Specification file name             
		
	inData.open(isoInfoFile_name);
	if ( !inData ){
		cerr << "Error: file "<< isoInfoFile_name <<" could not be opened" << endl;
      	exit(1);
	}
   	
   	if ( verbose )
   		cout << "Reading isolated info from " << isoInfoFile_name << "..." << endl;
   	inData >> junk; //First two "=="
   	
   	inData >> spec_file_name; 
   	//Gets rid of the ".ads" at the end 
   	for (int i = 0; i < 4; i++)  //".ads"
   		spec_file_name.pop_back(); 
  
   	
   	while ( !inData.eof() ) { //At this point, we are interested in the parameters, the returning type of the target function and its treatment
      getline(inData, line); 
      	  
	  if (line == "--------- Declaration of the target function -------------"){ //Function Name and returning type
	    getline(inData, junk); //First line is ignored
	    
	    inData >> word; //Reads the name 
	    if (word == "Name:"){
	    	inData >> function_name;
	    	if ( verbose )
	    		cout<<"Function name: "<< function_name << endl;
		}
		
		inData >> word; //Reads the returning type
	    if (word == "Returns:"){
	    	inData >> return_type;
	    	if ( verbose )
	    		cout<<"Returning type: "<< return_type << endl;
		}
		
		inData >> word; //Reads the returning type treatment
		if (word == "Treatment:"){
	    	inData >> return_type_treatment;
	    	if ( verbose )
	    		cout<<"Returning type treatment: "<< return_type_treatment << endl;
		}
	  }
	  
      if (line == "--------- Parameters of the target function -------------"){ //Parameters names, types and treatment	
	  	inData >> word;    
	    while ( true ){     	
		    if (word == "Line"){ //We ignore the rest of the line
				getline(inData, junk);
				inData >> word;
				continue;
			}
	    
		    if (word == "Name:"){ //Reads the name
		    	inData >> param_name;
		    	//cout<<"Parameter name: "<< param_name << endl;
		    	param_names.push_back( param_name );
			}
			
		    if (word == "Type:"){ //Reads the type
		    	inData >> param_type;
		    	//cout<<"Parameter type: "<< param_type << endl;
		    	param_types.push_back( param_type );
			}
			
			if (word == "Treatment:"){ //Reads the parameters appropiate treatment
				for (int i=0; i < param_names.size(); i++){
					inData >> word;
					if ( i < param_names.size() - 1 )
						word.pop_back(); //Deletes the comma at the end
					params_type_treatment.push_back( word );
					//We have to check if we need to include array support (maps are string arrays)
					if ( word == "Array" or word == "Map" )
						array_support = true;
				}
				
				break; //Loop exit
			}
			
			inData >> word;
		}
	  }

    }
    
    //Are there many parameters or just one?
    many_params = param_names.size() > 1;
    
    inData.close(); 
    if ( verbose )
       cout << "Done" << endl;
    
    //******************************************************************************************
    //Second part, reding data from the raw tests document obtained after executing the test oracle
    
	const string rawTestsFile_name = argv[2];  //Raw-Tests file name
	
    char list_char; 						   //Used for reading arrays
    int list_num;   					       //Used for reading array elements
    
    vector<string> test_vector;                //Information gathered in this second part
    vector<vector<string>> test_vectors; 
	pair<string, string> expected_result;      //The first element indicates whether it's an expected value or behaviour, the second is the content
	vector<pair<string,string>> expected_results;      
    string expected_value;
    string expected_behaviour;
    
	inData.open(rawTestsFile_name);
	if ( !inData ){
		cerr << "Error: file "<< rawTestsFile_name <<" could not be opened" << endl;
      	exit(1);
	}
    
    if ( verbose )
       cout << "Reading raw tests from " << rawTestsFile_name << "..." << endl;
    
    int cont_param = 0; //Counter of the actual parameter processed
    
   	while ( !inData.eof() ) { 
		inData >> word;
		
		//Collecting test vectors content----
		if (word == "vector:"){
			if ( many_params )
				inData >> junk_char; //Opening parenthesis 
			
			while ( cont_param < param_names.size() ){
				if ( params_type_treatment[cont_param] == "Int" ){  //Int treatment
					inData >> word;
					
					if ( word.back() == ',' or word.back() == ')' ) //If last char is a comma or a parenthesis, we delete it
						word.pop_back(); 
					
					Int_Param_Treatment( word );  
				}
				
				if ( params_type_treatment[cont_param] == "Real" ){  //Real treatment
					inData >> word;
					
					if ( word.back() == ',' or word.back() == ')' ) //If last char is a comma or a parenthesis, we delete it
						word.pop_back(); 

					Real_Param_Treatment( word );
				}
				
				if ( params_type_treatment[cont_param] == "Array" ){ //Array treatment				
					word = ""; //Resets the string word
					inData >> junk_char; //Opening bracket
					do{
						inData >> list_num; //We read a list element
						string str_list_num = to_string(list_num);
						Int_Param_Treatment( str_list_num ); //We only use Integer Array;
						word += str_list_num; 
						
						inData >> list_char; //We read the following comma or closing bracket
						if ( list_char == ',' ){
							word.push_back(',');
						}
					}while (list_char != ']');	
					inData >> junk_char; //Middle comma or final parenthesis				
				}
				
				if ( params_type_treatment[cont_param] == "Map" ){ //Map treatment			
					word = ""; //Resets the string word
					inData >> junk_char; //Opening bracket
					do{
						//We read a map element, which is a string delimited by single or double quotes
						inData >> list_char; 
						if ( list_char == '"' or list_char == '\'' ){
							inData >> list_char;
							do{	
								word.push_back(list_char);
								inData >> list_char;
							}while( list_char != '"' and list_char != '\'' );
						}
						
						inData >> list_char; //We read the following comma or closing bracket
						if ( list_char == ',' ){
							word.push_back(',');
						}
					}while (list_char != ']');	
					inData >> junk_char; //Middle comma or final parenthesis				
				}
				
				if ( params_type_treatment[cont_param] == "Enumerate" ){ //Enumerate treatment	
					word = ""; //Resets the string word
					//We read an enumerate element, which is a string delimited by single or double quotes
					inData >> list_char; 
					if ( list_char == '"' or list_char == '\'' ){
						inData >> list_char;
						do{	
							word.push_back(list_char);
							inData >> list_char;
						}while( list_char != '"' and list_char != '\'' );
					}						
				}
					
				//We add the parameter processed to the test vector
				test_vector.push_back( word ); 
				
				//Loop index update
				cont_param++;
			}//End of while loop
			
			cont_param = 0; //Reset
			
			test_vectors.push_back(test_vector); //We add the test vector to the total 
			test_vector.clear(); //Reset
		}
		
		//Collecting expected values associated to the test vectors, if they exist----
	    if (word == "value:"){	    		    
	    	if ( return_type_treatment == "Int" ){  //Int treatment
				inData >> expected_value;
				Int_Param_Treatment( expected_value );      
			}
			
	    	if ( return_type_treatment == "Real" ){  //Int treatment
				inData >> expected_value;
				Real_Param_Treatment( expected_value );      
			}			
			
			if ( return_type_treatment == "Bool" ) //Bool treatment
				inData >> expected_value;
			
			if ( return_type_treatment == "none" ){ //Target function is indeed a procedure so this expected value must be an "Error"
	    		inData >> expected_value;
	    		assert( expected_value == "Error" );
			}
			
			expected_result.first = "Value";
			expected_result.second = expected_value;
			expected_results.push_back( expected_result );
		}
		
		//Colecting expected behaviour associated to the test vectors, if they exists---
		if (word=="behaviour:") {
			getline(inData, expected_behaviour); //We read the rest of the line
			expected_result.first = "Behaviour";

			Translate_Behaviour_Expression( expected_behaviour );
			
			expected_result.second = expected_behaviour;
			expected_results.push_back( expected_result );
		}	
		
		//Collecting expected result associated to a random test
		if (word=="random:"){
	    	if ( return_type_treatment == "Int" ){  //Int treatment
				inData >> expected_value;
				Int_Param_Treatment( expected_value );      
			}
			
	    	if ( return_type_treatment == "Real" ){  //Int treatment
				inData >> expected_value;
				Real_Param_Treatment( expected_value );      
			}			
			
			if ( return_type_treatment == "Bool" ) //Bool treatment
				inData >> expected_value;
			
			if ( return_type_treatment == "none" ){ //Target function is indeed a procedure 
	    		inData >> expected_value;
	    		assert(expected_value != "Error");
			}
			
			expected_result.first = "Random";
			expected_result.second = expected_value;
			expected_results.push_back( expected_result );
		}	
    }
    	 	
	inData.close();
	if ( verbose )
       cout << "Done" << endl;
        
    //******************************************************************************************
    //Third part, gathering all the information and creating Ada Unit Tests
    if ( verbose )
       cout << "Creating Ada Unit Tests..." << endl;
    
	string test_name;                 //Test name
    string test_variables;            //Input, expected value or behaviour and actual output
    string test_body_1, test_body_2;  //Test body divided in 2 parts
    string test_end;                  //Test ending
    
    string test_case;                 //Single unit test case
    string test_cases = "";           //Here I will store a string with all the unit test cases
    string register_routine;          //Single routine registration
    string register_routines = "";    //Here I will store a string with all the register routines   
    
    //Input may need a record data if there are more than one parameter involved
    string test_vector_type;
    string record_definition = "";
    if ( many_params ){
    	test_vector_type = "Input";
    	record_definition += "type Input is record \n";
    	for(int i = 0; i < param_names.size(); i++)
    		record_definition += ("\t" + param_names[i] + " : " + param_types[i] + ";\n");
    	record_definition += "end record;\n";
	}
	else{ //No record needed, input consists of a single parameter
		test_vector_type = param_types[0];
	}
    
    //---Afterwards, we proceed to create all the test cases...
    string test_vector_translation;     //String with the translation of the input for the test name. E.g : 1.0 => 1dot0
    string expected_value_translation;  //String with the translation of the expected value for the test name
    
    for(int i = 0; i < test_vectors.size(); i++){ 
	
		//-------------First, we fix the test name------------ 
    	test_vector_translation = ""; 
    	for(int j = 0; j < test_vectors[i].size(); j++){
    		test_vector_translation += test_vectors[i][j];
    		if ( j < test_vectors[i].size() - 1 ) //Adds _ except for the last loop iteration
    			test_vector_translation += "_";
		}
		//We translate "." to "dot" and "-" to "minus"
		test_vector_translation = regex_replace(test_vector_translation, regex("\\."), "dot");
		test_vector_translation = regex_replace(test_vector_translation, regex("\\-"), "minus");
		//If the parameters contain commas because their type is "Array", we translate them as well
		if ( array_support ){
			test_vector_translation = regex_replace(test_vector_translation, regex("\\,"), "_");//We replace commas for underscores
		}
		//In addition, if the parameters contain any "None" due to lack of constraints on that element in the test oracle,
		//we translate it into "Any" since any value would do
		test_vector_translation = regex_replace(test_vector_translation, regex("None"), "Any");
		
		//We also process the expected value, if it exists
		//Note that expected behaviours have no specific representation in the test name, just the expected values. E.g : Expect_0
		expected_value_translation = "";
		if ( expected_results[i].first == "Value" or expected_results[i].first == "Random" ){
			expected_value_translation = expected_results[i].second;
			expected_value_translation = regex_replace(expected_value_translation, regex("\\."), "dot");
			expected_value_translation = regex_replace(expected_value_translation, regex("\\-"), "minus");
			if ( array_support ){
				expected_value_translation = regex_replace(expected_value_translation, regex("\\,"), "_");//We replace commas for underscores			
			}			
		}		
    	
    	//---Gathering the previous translations to generate the test name
    	assert (test_vector_translation != "" and (expected_value_translation != "" or expected_results[i].first == "Behaviour"));
    	
    	if ( expected_results[i].first == "Value" ){   //Test name design for expected values 
    		test_name =  function_name + "_" + test_vector_translation + "_Expect_" + expected_value_translation;
		}
		else if ( expected_results[i].first == "Random" ) {    //Test name design for random tests                                     			
			test_name =  "Random_" + to_string(i) + "_" + function_name + "_" + test_vector_translation + "_Expect_" + expected_value_translation;
		}
		else {                                        //Test name design for expected behaviours
			test_name =  function_name + "_" + test_vector_translation;
		}
				
		//End of the test case-----------
		test_end = "end " + test_name + ";\n\n";		
				  
    	//---------Next, we fix the body of the test case-------------
    	string test_vector_initialization = "";  
    	
    	if ( many_params )
    		test_vector_initialization += "(";
    		
		//'i' index refers to the number of test case (one per test vector), 'j' index refers to the parameter of the test vector
		for(int j = 0; j < test_vectors[i].size(); j++){
			test_vector_initialization += test_vectors[i][j];
				
			if ( params_type_treatment[j] == "Array" or params_type_treatment[j] == "Map" ) //We add parenthesis
				test_vector_initialization = "(" + test_vector_initialization + ")";
				
		   	if ( j < test_vectors[i].size() - 1 )
		   		test_vector_initialization += ", ";  		    
		}
		
		if ( many_params )
    		test_vector_initialization += ")";
		
		string actual_expected_result = expected_results[i].second; //Expected result for the actual test vector
			
		//----Depending on whether expected result is a value or a behaviour, we have different test bodies
		if ( (expected_results[i].first == "Value" or (expected_results[i].first == "Random" and actual_expected_result != "none" ) )
		  and actual_expected_result != "Error" ){  //Test body design for expected values
			test_variables = "\tTest_Vector : " + test_vector_type + " := " + test_vector_initialization + ";\n" +
						     "\tExpected_Output : " + return_type + " := " + actual_expected_result + ";\n" +
			   				 "\tActual_Output : " + return_type + ";\n";
		}
		else{   //Test body design for expected behaviours as well as intentional erroneous tests
			test_variables = "\tTest_Vector : " + test_vector_type + " := " + test_vector_initialization + ";\n";
			if ( return_type != "nothing" ) //If target function is not a procedure indeed, we also need an Actual_Output
				test_variables += "\tActual_Output : " + return_type + ";\n";
		}
		
		if ( old_attribute_support ) //Old attribute simulation
			test_variables += "\t"+ old_attribute_simulation +";\n";
		
		//----We continue with the first part of the test case body , including the call to the target function and the following Assert  
		test_body_1 = "begin\n"; 
		
		if ( !many_params ){
			if ( return_type != "nothing" )
				test_body_1 += "\tActual_Output := " + function_name + "( Test_Vector );\n\n";
			else
				test_body_1 += "\t" + function_name + "( Test_Vector );\n\n";
		}
		else{  //If test vector is a record, we need to refer to the fields of the record one by one when calling the function
			if ( return_type != "nothing" )
				test_body_1 += "\tActual_Output := " + function_name + "( ";
			else
				test_body_1 += "\t" + function_name + "( ";
				
			for(int h=0; h < param_names.size(); h++){
					test_body_1 += "Test_Vector." + param_names[h];
					if (h < param_names.size() - 1) //If it is not the last iteration
						test_body_1 += ", ";
					else
						test_body_1 += " );\n\n";
			}
		}
		
		//----Now we deal with the Assert instruction and its message, the second part of the test body
		if ( actual_expected_result != "Error" ){
			test_body_2 = "\tAssert( ";
			
			if ( expected_results[i].first == "Value" ){             //Assert design for expected values
				test_body_2 += "Actual_Output = Expected_Output,\n";
				test_body_2 += "\t\t\"For test vector \"& Test_Vector'Image &\", expected value: \"& Expected_Output'Image &\", got result: \"& Actual_Output'Image );\n\n";
			}
			else if ( expected_results[i].first == "Behaviour" ){    //Assert design for expected behaviours
				test_body_2 += actual_expected_result + ",\n";
				test_body_2 += "\t\t\"For test vector \"& Test_Vector'Image &\", expected behaviour: " + actual_expected_result + "\" );\n\n";			
			}	
			else{                                                    //Assert design for random tests
				if ( actual_expected_result != "none" ){
					test_body_2 += "Actual_Output = Expected_Output,\n";
					test_body_2 += "\t\t\"For test vector \"& Test_Vector'Image &\", expected value: \"& Expected_Output'Image &\", got result: \"& Actual_Output'Image );\n\n";	
				}
				else{ //We are working with a procedure
					test_body_2 = ""; //Reset
					//test_body_2 = "\tPut_Line(\"This is a random test for a procedure, there is no expected returning type to generate...\");";
					test_body_2 += "\n\n";
				}
			}		
		}
		else //We are dealing with an intentionally erroneous test
			test_body_2 = "\tPut_Line( \"This test should have failed...\");\n\n";
			
		
		//-----Gathering all the pieces of the test case together--------
		test_case = "procedure " + test_name + " (TC : in out AUnit.Test_Cases.Test_Case'Class) is\n" + test_variables + test_body_1 + test_body_2 + test_end;
		test_cases += test_case;  //This string will later on be inserted in the proper text template
		
		//-----Associated register routine----			
		register_routine = "\tRegister_Routine (Test => T,\n\t\tRoutine => " + test_name;
		register_routine += "'Access,\n\t\tName => \"" + test_name +"\");\n";;
		register_routines += register_routine; //This string will later on be inserted in the proper text template
	}
	
	if ( verbose )
       cout << "Done" <<endl;
    
    //******************************************************************************************
    //Fourth and last part, integrating the Ada Unit Tests created previously using text templates
    
	ofstream outData;  //OUT file stream
    
    //Harness Template
    inData.open("../Ada_Test_Creator/Templates/Harness_Template.txt");
	if ( !inData ){
		cerr << "Error: file Harness_Template.txt could not be opened" << endl;
      	exit(1);
	}
    stringstream buffer;
	buffer << inData.rdbuf(); //Reads the whole file
	inData.close();
	
    string harness = buffer.str();
    harness = regex_replace(harness, regex("<function_name>"), function_name);
    
    outData.open("./_test/harness/"+function_name+"_Harness.adb");
    outData << harness; //Creates the harness
    outData.close();
    
    //Suite templates
    //--Spec
    inData.open("../Ada_Test_Creator/Templates/Suite_Spec_Template.txt");
	if ( !inData ){
		cerr << "Error: file Suite_Spec_Template.txt could not be opened" << endl;
      	exit(1);
	}
    buffer.str(""); //Resets the buffer
	buffer << inData.rdbuf(); //Reads the whole file
	inData.close();
	
    string suite_spec = buffer.str();
    suite_spec = regex_replace(suite_spec, regex("<function_name>"), function_name);
    
    outData.open("./_test/harness/"+function_name+"_Suite.ads");
    outData << suite_spec; 
    outData.close();
    
    //--Body
    inData.open("../Ada_Test_Creator/Templates/Suite_Body_Template.txt");
	if ( !inData ){
		cerr << "Error: file Suite_Body_Template.txt could not be opened" << endl;
      	exit(1);
	}
    buffer.str(""); //Resets the buffer
	buffer << inData.rdbuf(); //Reads the whole file
	inData.close();
	
    string suite_body = buffer.str();
    suite_body = regex_replace(suite_body, regex("<function_name>"), function_name);   
    suite_body = regex_replace(suite_body, regex("<spec_file>"), spec_file_name); 
    
    outData.open("./_test/harness/"+function_name+"_Suite.adb");
    outData << suite_body; 
    outData.close();
    
    //Test_Cases templates
    //--Spec
    inData.open("../Ada_Test_Creator/Templates/Test_Spec_Template.txt");
	if ( !inData ){
		cerr << "Error: file Test_Spec_Template.txt could not be opened" << endl;
      	exit(1);
	}
    buffer.str(""); //Resets the buffer
	buffer << inData.rdbuf(); //Reads the whole file
	inData.close();
	
    string test_spec = buffer.str();
    test_spec = regex_replace(test_spec, regex("<function_name>"), function_name);   
    test_spec = regex_replace(test_spec, regex("<spec_file>"), spec_file_name);   
	
    outData.open("./_test/test_cases/"+spec_file_name+"-Test_"+function_name+".ads");
    outData << test_spec; 
    outData.close(); 
	
	//--Body
    inData.open("../Ada_Test_Creator/Templates/Test_Body_Template.txt");
	if ( !inData ){
		cerr << "Error: file Test_Body_Template.txt could not be opened" << endl;
      	exit(1);
	}
    buffer.str(""); //Resets the buffer
	buffer << inData.rdbuf(); //Reads the whole file
	inData.close();
	
    string test_body = buffer.str();
    test_body = regex_replace(test_body, regex("<function_name>"), function_name);   
    test_body = regex_replace(test_body, regex("<spec_file>"), spec_file_name); 
	test_body = regex_replace(test_body, regex("<test_cases>"), test_cases);
	test_body = regex_replace(test_body, regex("<register_routines>"), register_routines);
	if ( int_support ){
		string max_min_integers = "MaxInt : constant Integer := " + MaxInt + ";\nMinInt : constant Integer := " + MinInt + ";";
		test_body = regex_replace(test_body, regex("<int_support>"), max_min_integers);
	}		
	else
		test_body = regex_replace(test_body, regex("<int_support>"), ""); //empty string
	
	if ( test_vector_type == "Input" )	 //Test type may requiere a record 
		test_body = regex_replace(test_body, regex("<record_definition>"), record_definition);
	else
		test_body = regex_replace(test_body, regex("<record_definition>"), "");
    
    outData.open("./_test/test_cases/"+spec_file_name+"-Test_"+function_name+".adb");
    outData << test_body; 
    outData.close(); 
    
    //---Finally we create the .gpr to compile everything with instrumentation for gcov
    inData.open("../Ada_Test_Creator/Templates/ProjectGpr_Template.txt");
	if ( !inData ){
		cerr << "Error: file ProjectGpr_Template.txt could not be opened" << endl;
      	exit(1);
	}
    buffer.str(""); //Resets the buffer
	buffer << inData.rdbuf(); //Reads the whole file
	inData.close();
	
    string gpr = buffer.str();
    gpr = regex_replace(gpr, regex("<function_name>"), function_name);   
    gpr = regex_replace(gpr, regex("<spec_file>"), spec_file_name); 
    
    outData.open("./"+spec_file_name+"_"+function_name+".gpr");
    outData << gpr; 
    outData.close(); 
    
    return 0;
}


//--------------------------------------------------------Auxiliary functions implementation----------------------

void Int_Param_Treatment ( string & param ){
	//Make sure it has NO decimal part
	assert( param.find('.') == string::npos ); 		
	//Fix a posible "None" value due to lack of constraints on this parameter in the test oracle
	if ( param == "None" )
		param = "0"; 
	//Max and Min Integers
	if ( param == MaxInt ){
		param = "MaxInt";
		int_support = true;
	}		
	if ( param == MinInt ){
		param = "MinInt";
		int_support = true;
	}
}

void Real_Param_Treatment ( string & param ){
	//Fix a posible "None" value due to lack of constraints on this parameter in the test oracle
	if ( param == "None" )
		param = "0.0";
	//Make sure it DOES have decimal part. In python, 1 is equal to 1.0 but not in Ada 
	if ( param.find('.') == string::npos ) 
		param = param + ".0";  
}

void Translate_Behaviour_Expression( string & behaviour_expression ){
	string behaviour_regex;
	if ( !many_params ) {
		behaviour_regex = "\\s"+param_names[0]+"\\s"; //White spaces 
		behaviour_expression = regex_replace(behaviour_expression, regex(behaviour_regex), " Test_Vector ");
		behaviour_regex = "\\s"+param_names[0]+"\\("; //White space + "("
		behaviour_expression = regex_replace(behaviour_expression, regex(behaviour_regex), " Test_Vector(");
		behaviour_regex = "\\s"+param_names[0]+"$"; //White space + "$"
		behaviour_expression = regex_replace(behaviour_expression, regex(behaviour_regex), " Test_Vector");
		//If array support is needed we might as well need to translate the Array'Range call
		if ( array_support  ){
			behaviour_regex = param_names[0]+"\'Range";
			behaviour_expression = regex_replace(behaviour_expression, regex(behaviour_regex), "Test_Vector'Range");	
		}	
	}
	else { //There are more than 1 parameter, each one must be individually called by Test_Vector.<param_name>
		for ( int h=0; h < param_names.size(); h++ ){
			if( behaviour_expression.find( param_names[h]+"'Old" ) != string::npos ){ //We might need to simulate a Old attribute call
				old_attribute_support = true;
				old_attribute_simulation = param_names[h]+"_Old : "+ param_types[h] +" := Test_Vector."+ param_names[h];
				behaviour_expression = regex_replace(behaviour_expression, regex(param_names[h]+"\\'Old"), param_names[h]+"_Old");
			}
			behaviour_regex = "\\s"+param_names[h]+"\\s"; //White spaces 
			behaviour_expression = regex_replace(behaviour_expression, regex(behaviour_regex), " Test_Vector."+param_names[h]+" ");
			behaviour_regex = "\\s"+param_names[h]+"\\("; //White space + "("
			behaviour_expression = regex_replace(behaviour_expression, regex(behaviour_regex), " Test_Vector."+param_names[h]+"(");
			behaviour_regex = "\\s"+param_names[h]+"$"; //White space + "$"
			behaviour_expression = regex_replace(behaviour_expression, regex(behaviour_regex), " Test_Vector."+param_names[h]);
			//If array support is needed we might as well need to translate the Array'Range call
			if ( array_support  ){
				behaviour_regex = param_names[h]+"\'Range";
				behaviour_expression = regex_replace(behaviour_expression, regex(behaviour_regex), "Test_Vector."+param_names[h]+"'Range");	
			}
		}
	}
	//We also have to translate <target_function>'Result => Actual_Output;
	behaviour_regex = function_name +"\'Result";
	behaviour_expression = regex_replace(behaviour_expression, regex(behaviour_regex), "Actual_Output");	
}

