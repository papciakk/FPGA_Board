#include <SDL/SDL.h>
#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include <iostream>
#include <fstream>
#include <math.h>

#include <SDL/SDL_rotozoom.h>
#include <SDL/SDL_gfxPrimitives.h>
#include <SDL/SDL_framerate.h>

using namespace std;

const int sin_lut [] = {
	0,    143,  286,  429,  571,  714,  856,  998,  1140, 1281, 1422,
	1563, 1703, 1843, 1982, 2120, 2258, 2395, 2531, 2667, 2801, 2935,
	3068, 3200, 3332, 3462, 3591, 3719, 3845, 3971, 4096, 4219, 4341,
	4461, 4580, 4698, 4815, 4929, 5043, 5155, 5265, 5374, 5481, 5586,
	5690, 5792, 5892, 5991, 6087, 6182, 6275, 6366, 6455, 6542, 6627,
	6710, 6791, 6870, 6946, 7021, 7094, 7164, 7232, 7298, 7362, 7424,
	7483, 7540, 7595, 7647, 7697, 7745, 7790, 7833, 7874, 7912, 7948,
	7981, 8012, 8041, 8067, 8090, 8111, 8130, 8146, 8160, 8171, 8180,
	8186, 8190, 8191
};

struct line3d {
	int x0,y0,z0;
	int x1,y1,z1;
	
	line3d (int _x0, int _y0, int _z0, int _x1, int _y1, int _z1) 
		: x0(_x0),y0(_y0),z0(_z0), x1(_x1),y1(_y1), z1(_z1) {}
};

vector <line3d> lines;


void getSinCos(int x, int &sin, int &cos) {	
	if (x >= 270) {
		sin = -sin_lut[360-x];
		cos = sin_lut[x-270];
	} 
	else if (x >= 180) {
		sin = -sin_lut[x-180];
		cos = -sin_lut[270-x];
	} 
	else if (x >= 90) {
		sin = sin_lut[180-x];
		cos = -sin_lut[x-90];
	} 
	else {
		sin = sin_lut[x];
		cos = sin_lut[90-x];
	}
}

int getSin(int x) {
	x %= 360;
	
	return (x >= 270) ? (-sin_lut[360-x]) : ( (x >= 180) ? (-sin_lut[x-180]) : ( (x >= 90) ? sin_lut[180-x] : sin_lut[x] ) );
}

int getCos(int x) {
	return getSin(x+90);
}

void loadData(const char *fn) {
	ifstream in (fn);
	
	int x0,x1,y0,y1,z0,z1;
	
	while(!in.eof()) {
		in >> x0 >> y0 >> z0 >> x1 >> y1 >> z1;
		lines.push_back(line3d(x0,y0,z0,x1,y1,z1));
	}
}

int main(int argc, char *argv[]) {
	
	if(argc != 2) {
		cout << "Improper number of arguments!\nUsage: " << argv[0] << " <filename>";
		return 1;
	}
	
	loadData(argv[1]);
	
	if(SDL_Init(SDL_INIT_VIDEO) == -1) {
		fprintf(stderr, "Failed to initialize SDL: %s\n", SDL_GetError());
		exit(1);
	}
	atexit(SDL_Quit);

	SDL_Surface *screen = SDL_SetVideoMode(640, 480, 8, SDL_HWSURFACE|SDL_DOUBLEBUF);
	if(screen == NULL){
		fprintf(stderr, "Unable to set video mode: %s\n", SDL_GetError());
		exit(1);
	}

	
	FPSmanager fpsm;
	SDL_initFramerate(&fpsm);
	SDL_setFramerate(&fpsm, 60);

	bool isRunning = true;
	
	
	int x0,x1,y0,y1,z0,z1,t;
	
	int ax = 100;
	int ay = 30;
	int az = 254;
	
	int s=10;
	
	while(isRunning) {
		
		// ******************* INPUTS *************************
		
		Uint8 *k = SDL_GetKeyState(NULL);
		
		if(k['q']) az = (az < 360) ? az + 1 : 0;
		if(k['e']) az = (az > 0) ? az - 1 : 360;
		if(k['a']) ay = (ay < 360) ? ay + 1 : 0;
		if(k['d']) ay = (ay > 0) ? ay - 1 : 360;
		if(k['w']) ax = (ax < 360) ? ax + 1 : 0;
		if(k['s']) ax = (ax > 0) ? ax - 1 : 360;
		
		if(k['z']) s++;
		if(k['x']) s--;
	
	
		// ******************* GRAPHICS *************************		
		
		int sinx, cosx;
		getSinCos(ax, sinx, cosx);
		
		int siny, cosy;
		getSinCos(ay, siny, cosy);
		
		int sinz, cosz;
		getSinCos(az, sinz, cosz);
		
	 	SDL_FillRect(screen, NULL, 0);
	 
	 	for(int i=0; i<lines.size(); i++) {
	 
		 	x0 = lines[i].x0;
			y0 = lines[i].y0;
			z0 = lines[i].z0;
			x1 = lines[i].x1;
			y1 = lines[i].y1;
			z1 = lines[i].z1;
		 
		 	// rot x
		 	t = y0*cosx-z0*sinx;
		 	z0 = y0*sinx+z0*cosx;
		 	y0 = t;
		 	t = y1*cosx-z1*sinx;
		 	z1 = y1*sinx+z1*cosx;
		 	y1 = t;
		 	
		 	y0 >>= 13;
		 	z0 >>= 13;
		 	y1 >>= 13;
		 	z1 >>= 13;
		 	
		 	// rot y
		 	t = x0*cosy+z0*siny;
		 	z0 = -x0*siny+z0*cosy;
		 	x0 = t;
		 	t = x1*cosy+z1*siny;
		 	z1 = -x1*siny+z1*cosy;
		 	x1 = t;
		 	
		 	x0 >>= 13;
		 	z0 >>= 13;
		 	x1 >>= 13;
		 	z1 >>= 13;
		 
		 	// rot z
		 	t  = x0*cosz-y0*sinz;
		 	y0 = x0*sinz+y0*cosz;
		 	x0 = t;
		 	t  = x1*cosz-y1*sinz;
		 	y1 = x1*sinz+y1*cosz;
		 	x1 = t;
		 	
		 	x0 >>= 13;
		 	y0 >>= 13;
		 	x1 >>= 13;
		 	y1 >>= 13;
		 	
		 	// scale
		 	x0 = x0 + (x0*s) >> 4;
		 	y0 = y0 + (y0*s) >> 4;
		 	z0 = z0 + (z0*s) >> 4;
		 	x1 = x1 + (x1*s) >> 4;
		 	y1 = y1 + (y1*s) >> 4;
		 	z1 = z1 + (z1*s) >> 4;
		
			lineColor (screen, z0/60+320, y0/60+240, z1/60+320, y1/60+240, 0xFFFFFFFF);
		}

		SDL_Flip(screen);
		SDL_framerateDelay(&fpsm);
	
		SDL_Event event;
		while(SDL_PollEvent(&event)){
			switch(event.type){
			case SDL_QUIT:
				isRunning = false;
				break;
			case SDL_KEYDOWN:
				if(event.key.keysym.sym == SDLK_ESCAPE)
					isRunning = false;
			}
		}	
	}
	
	return 0;
}
