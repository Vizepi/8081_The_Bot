#ifndef __8081_INPUT_HPP
#define __8081_INPUT_HPP

#include <ShSDK/ShSDK.h>
#include <ShStd/ShStd.h>

class Input
{

public:

	enum EInput
	{
		// In game inputs
		e_input_up,
		e_input_down,
		e_input_left,
		e_input_right,
		e_input_fire,
		e_input_shield,
		e_input_action,
		e_input_pause,
		
		e_input_count // Keep at the end of enum
	};

	explicit			Input	(void);
	virtual				~Input	(void);



protected:


};

#endif // __8081_INPUT_HPP