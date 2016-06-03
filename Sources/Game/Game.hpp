
class Game
{
public:
	
	static void OnPreInitialize(void);
	static void OnPostInitialize(void);
	static void OnPreUpdate(float dts);
	static void OnPostUpdate(float dts);
	static void OnPreRelease(void);
	static void OnPostRelease(void);
	static void OnTouchDown(int iTouch, float positionX, float positionY);
	static void OnTouchUp(int iTouch, float positionX, float positionY);
	static void OnTouchMove(int iTouch, float positionX, float positionY);

private:


};