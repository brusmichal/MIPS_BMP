#define MAX_X 10
#define MAX_Y 10
#include <iostream>

int main(){
    int x=0, y=0;

    for(int j=0; j< MAX_Y; j++){

        for(int i=0; i < MAX_X; i++){

            int width = check_width(x, y);
            int heigth = check_heigth(x, y);
            if(width == heigth){
                int thick_right = check_heigth(x+ width, y);>
                int thick_up =  check_width(x, y + heigth);
                if(thick_right == thick_up){
                    int inner_width = check_width(x + thick_up, y + thick_right);
                    int inner_height = check_heigth(x + thick_up, y + thick_right);
                    if((inner_height == inner_width){
                            if((thick_right + inner_height) == (thick_up + inner_width) ){
                                for(int j=y; j < thick_right; j++){
                                    if(check_width(x,j) == width)
                                        continue;
                                    else
                                        break;
                                };
                                for(int j=thick_right; j < heigth; j++){
                                    if(check_width(x,j) == thick_up)
                                        continue;
                                    else
                                        break;
                                };
                                
                                std::cout << "Wierzchołek znacznika:" << "(" << x << ", " << y << ")" << std:endl;
                            }    
                        }
                    }

                }
            }
        }
    };
}

bool isBlack(int x, int y){};

int check_width(int x, int y){
   int width = 0;
    while(isBlack(x, y)){
        width++;
        x++;
    }
    return width;
};
int check_heigth(int x, int y){
   int heigth = 0;
    while(isBlack(x, y)){
        heigth++;
        y++;
    }
    return heigth;
};
