import com.shigeodayo.ardrone.manager.*;
import com.shigeodayo.ardrone.navdata.*;
import com.shigeodayo.ardrone.utils.*;
import com.shigeodayo.ardrone.processing.*;
import com.shigeodayo.ardrone.command.*;
import com.shigeodayo.ardrone.*;
import procontroll.*;
import java.io.*;

import krister.Ess.*;

//フレーズを分析できる

ARDroneForP5 ardrone;

//楽器・キーの設定
int mode = 1;    //(0:F調オカリナ ,1:C調オルガン)

/* Garage Band のオススメ設定
    楽器名：Cathedral Organ  Scale:3,  mode:1

   android xPiano
    楽器名：Chuch Organ  Scale:3,  mode:1
*/

//Sound
FFT myfft;
AudioInput myinput;
int bufferSize=1024;

//再生用チャンネル
AudioChannel myChannel;

//Procontrolでキーを割り当てる
ControllIO controll;
ControllDevice device;
ControllDevice tpad;
ControllSlider SX,SY;
ControllButton BUP,BDOWN,BRIGHT,BLEFT;
ControllButton BS,BR,BL,BU,BD,BZ;
ControllButton BSHIFT,BCTRL;
ControllButton B1,B2,B3,B4,B5,B8;

//Essの設定
int n;			//何かに使う数字

int lengt = 2;		//過去何回分の周波数を平均するか
int phlengt = 50;	//録音するフレーズの長さ(*0.1秒)

float thre = 0.3; 	//パワースペクトルがこの値を超えたら音を分析する

int renew = 0;		//フラグ(配列を更新するか)

int pitchmax;		//分析する周波数の最大値
int[] durationbox = new int[lengt * 2];		//過去の音程を入れておく配列
float[] powerbox = new float[lengt * 2];	//過去の音量を入れておく配列

int[] phrase = new int[phlengt];		//過去の音階を入れておく配列
char[] cphrase = new char[phlengt];		//過去の音階(Char型)を入れておく配列

int[] seq = new int[phlengt];			//音階の遷移を入れておく配列
int seqn = 0;                                   //音階の遷移配列の長さ

int dura1,dura2;	//周波数の変化を見るための変数
float power1,power2;    //音量の変化を見るための変数

float strong;		//スペクトルの最大値を調べるための変数

int phrase0;		//分析した音階を配列に入れるための変数
char cphrase0;  	//分析した音階(Char型)を配列に入れるための変数

int x1 = 360;		//表示位置
int y1 = 10;		//上に同じ
int x2 = 200;		//上に同じ
int y2 = 300;		//上に同じ

int flage;		//フラグ(音を鳴らしているか)
float flagtime;		//次に音を再生するまでの時間

int flagf;              //フラグ(フレーズと一致したか)

//音階の設定
int m0l,m0h,m1l,m1h,m2l,m2h,m3l,m3h,m4l,m4h,m5l,m5h,m6l,m6h,m7l,m7h,m8l,m8h,m9l,m9h;
char cp1,cp2,cp3,cp4,cp5,cp6,cp7;

//Color
color c0 = color(255,255,255);
color c1 = color(192,192,0);

//mp3ファイルの場所./data
String sname = "./data/namae.mp3";
String sririku = "./data/ririku.mp3";
String schakuriku = "./data/chakuriku.mp3";
String smae = "./data/mae.mp3";
String sushiro = "./data/ushiro.mp3";
String smigi = "./data/migi.mp3";
String shidari = "./data/hidari.mp3";
String sup = "./data/up.mp3";
String sdown = "./data/down.mp3";
String ssmigi = "./data/smigi.mp3";
String sshidari = "./data/shidari.mp3";


void setup(){
  //Window Size
  size(560,500);
  
  //AR.Drone Settings
  ardrone=new ARDroneForP5("192.168.1.220");
  //AR.Droneに接続，操縦するために必要
  ardrone.connect();
  //AR.Droneからのセンサ情報を取得するために必要
  ardrone.connectNav();
  //AR.Droneからの画像情報を取得するために必要
  ardrone.connectVideo();
  //これを宣言すると上でconnectした3つが使えるようになる．
  ardrone.start();
  
  //Start Ess
  Ess.start(this);
  myinput=new AudioInput(bufferSize);
  myfft=new FFT(bufferSize*2);
  myinput.start();

  myfft.damp(.3);
  myfft.equalizer(true);
  myfft.limits(.005,.05);
  
  myChannel = new AudioChannel();
  myChannel.loadSound(sname);      //起動音
  
  //MacBookPro,Airのデバイス設定
  controll = ControllIO.getInstance(this);
  device = controll.getDevice(0);
  tpad = controll.getDevice(2);
  
  //MacBookPro,Airのキーボード設定
  SX = tpad.getSlider(0);
  SY = tpad.getSlider(1);
  BUP = device.getButton(89);
  BDOWN = device.getButton(88);
  BRIGHT = device.getButton(86);
  BLEFT = device.getButton(87);
  BS = device.getButton(29);
  BR = device.getButton(28);
  BL = device.getButton(22);
  BU = device.getButton(31);
  BD = device.getButton(14);
  BZ =device.getButton(36);
  BSHIFT = device.getButton(1);
  BCTRL = device.getButton(0);
  B1 = device.getButton(37);
  B2 = device.getButton(38);
  B3 = device.getButton(39);
  B4 = device.getButton(40);
  B5 = device.getButton(41);
  B8 = device.getButton(44);
  
  SX.setTolerance(5.0f);
  SY.setTolerance(5.0f);
  
  
  //調によって音階を設定
  switch(mode){
    case 0:
      m0l = 630;
      m0h = 670;
      m1l = 680;
      m1h = 720;
      m2l = 750;
      m2h = 800;
      m3l = 810;
      m3h = 910;
      m4l = 910;
      m4h = 970;
      m5l = 1000;
      m5h = 1080;
      m6l = 1150;
      m6h = 1200;
      m7l = 1250;
      m7h = 1350;
      m8l = 1350;
      m8h = 1450;
      m9l = 1500;
      m9h = 1600;
      
      cp1 = 'F';
      cp2 = 'G';
      cp3 = 'A';
      cp4 = 'B';
      cp5 = 'C';
      cp6 = 'D';
      cp7 = 'E';
      break;
      
    case 1:
      m0l = 940;
      m0h = 1010;
      m1l = 1010;
      m1h = 1080;
      m2l = 1150;
      m2h = 1200;
      m3l = 1250;
      m3h = 1350;
      m4l = 1350;
      m4h = 1450;
      m5l = 1500;
      m5h = 1600;
      m6l = 1700;
      m6h = 1800;
      m7l = 1900;
      m7h = 2030;
      m8l = 2030;
      m8h = 2150;
      m9l = 2300;
      m9h = 2400;
      
      cp1 = 'C';
      cp2 = 'D';
      cp3 = 'E';
      cp4 = 'F';
      cp5 = 'G';
      cp6 = 'A';
      cp7 = 'B';
      break; 
  }
  
}

//初期位置、速度、向き
float px = 0.0;    //position x
float py = 0.0;    //position y
float vx = 0.0;    //velocity x
float vy = 0.0;    //velocity y
float yawz = 0.0;  //yaw(now)-yaw(initial)
float mi1=0.0;     //the interval between mi2 and mi
float mi2=0.0;     //the last time caliculated


void draw(){
  //背景色
  background(160);

  //AR.Droneからの画像を取得
  PImage img=ardrone.getVideoImage(false);
  if(img==null)
    return;
  image(img, 0, 0);

  //AR.Droneからのセンサ情報を標準出力する．
  //ardrone.printARDroneInfo();
  //各種センサ情報を取得する
  float pitch=ardrone.getPitch();
  float roll=ardrone.getRoll();
  float yaw=ardrone.getYaw();
  float altitude=ardrone.getAltitude();
  float[] velocity=ardrone.getVelocity();
  int battery=ardrone.getBatteryPercentage();
  
  //アプレット起動後の時間
  float mi= millis();
  
  //状態量を表示
  String attitude="pitch:"+pitch+"\nroll:"+roll+"\nyaw:"+yaw+"\naltitude:"+altitude;
  text(attitude, 20, 265);
  String vel="VEL( "+velocity[0]+" , "+velocity[1]+" )";
  text(vel, 20, 335);
  String bat="battery:"+battery+" %";
  text(bat, 20, 350);
  String miil=mi+"msec";
  text(miil, 20, 365);
  String yaz="yawzero:"+yawz+"\nyawrel:"+(yaw-yawz);
  text(yaz, 20, 380);
  
  //Slider Settings
  float LX = SX.getValue();
  float LY = SY.getValue();
  String Sli = "Slider("+LX+","+LY+")";
  text(Sli,20,410);
  
  //ヨー角の初期値を得る
  if((mi>2990)&&(mi<3110)) yawz = ardrone.getYaw();
  
  
  //オイラー法の間隔(Minimum)
  int inter = 50;
  int i = 0;
 
  //velocity matrix
  float[][] veloci = new float[5000][9];
  
  //Estimating Position
  
  if((mi-mi2)>inter){
    mi1=mi-mi2;
  //オイラー法
    vx = velocity[0];
    vy = velocity[1];
    px += (vx*cos((yaw-yawz)/180*3.1416)*cos(pitch/180*3.1416)
            -vy*sin((yaw-yawz)/180*3.1416)*cos(roll/180*3.1416))*mi1/1000;
    py += (-vy*cos((yaw-yawz)/180*3.1416)*cos(pitch/180*3.1416)
            -vx*sin((yaw-yawz)/180*3.1416)*cos(roll/180*3.1416))*mi1/1000;;
    
    veloci[i][0]=mi;
    veloci[i][1]=mi1;
    veloci[i][2]=velocity[0];
    veloci[i][3]=velocity[1];
    veloci[i][4]=pitch;
    veloci[i][5]=roll;
    veloci[i][6]=yaw-yawz;
    veloci[i][7]=px;
    veloci[i][8]=py;
    
    i++;
    mi2=mi;
  }
  
  //位置を表示
  String pos="POS( "+px+" , "+py+" )";
  text(pos, 20, 320);
  
  
  //ここから音を扱う
  
  //パワースペクトルを表示
  for (int i3=0; i3<bufferSize;i3++) {
    rect(100.0*log(i3+10)-120,430,1,myfft.spectrum[i3]*-400);
    if(myfft.spectrum[i3] > thre){
      if(myfft.spectrum[i3] > strong){
        strong = myfft.spectrum[i3];
        pitchmax = i3;
      }
    }
  }
  
  //周波数を表示
  text("0",100.0*log(10)-130,445);
  for (int j=6; j < bufferSize; j = j*2){
    text(22050/bufferSize*j,100.0*log(j+10)-130,445);
  }
  
  //音量の変化を記録
  for(int m=2*lengt-1;m>0;m--){
      powerbox[m] = powerbox[m-1];
    }
  powerbox[0] = myfft.spectrum[pitchmax];

  //パワースペクトル最大の周波数を表示
  text("Now:" + 22050/bufferSize*pitchmax + "Hz" ,400,70);
  
  //周波数の変化を記録
  if(pitchmax < 100){
    for(int m=2*lengt-1;m>0;m--){
      durationbox[m] = durationbox[m-1];
    }
    durationbox[0] = pitchmax;
  }else{
  }
  
  //音階を比較
  for(int m=0;m<lengt;m++){
   dura1 += durationbox[m];
   dura2 += durationbox[m+lengt];
  }
  
  if(dura1 > dura2*1.2){
   text("PITCH UP",460,30); 
  }else if(dura1*1.2 < dura2){
   text("PITCH DOWN",460,30); 
  }
  
  //音量を比較
  for(int m=0;m<lengt;m++){
   power1 += powerbox[m];
   power2 += powerbox[m+lengt];
  }
  if(power1 > power2 + 0.5){
   text("VOLUME UP",460,50); 
  }else if(power1 < power2 - 0.5){
   text("VOLUME DOWN",460,50); 
  }
  
  //音階を分析する周波数
  int dura3 = dura1*22050/(bufferSize*lengt);
  text("Ave:" + dura3 + "Hz",400,90);
  
  //ここで音階を分析
  if(dura3 > m5l && dura3 < m5h){
    text("5 G (C)",x1,y1);
    phrase0 = 5;
    cphrase0 = cp5;
    renew = 1;
  }else if(dura3 > m4l && dura3 < m4h){
    text("4 F (Bb)",x1,y1);
    phrase0 = 4;
    cphrase0 = cp4;
    renew = 1;
  }else if(dura3 > m3l && dura3 < m3h){
    text("3 E (A)",x1,y1);
    phrase0 = 3;
    cphrase0 = cp3;
    renew = 1;
  }else if(dura3 > m2l && dura3 < m2h){
    text("2 D (G)",x1,y1);
    phrase0 = 2;
    cphrase0 = cp2;
    renew = 1;
  }else if(dura3 > m1l && dura3 < m1h){
    text("1 C (F)",x1,y1);
    phrase0 = 1;
    cphrase0 = cp1;
    renew = 1;
  }else if(dura3 > m0l && dura3 < m0h){
    text("0 Low B (Low E)",x1,y1);
    phrase0 = 0;
    cphrase0 = cp7;
    renew = 1;
  }else if(dura3 > m6l && dura3 < m6h){
    text("6 A (D)",x1,y1);
    phrase0 = 6;
    cphrase0 = cp6;
    renew = 1;
  }else if(dura3 > m7l && dura3 < m7h){
    text("7 B (E)",x1,y1);
    phrase0 = 7;
    cphrase0 = cp7;
    renew = 1;
  }else if(dura3 > m8l && dura3 < m8h){
    text("8 High C (High F)",x1,y1);
    phrase0 = 8;
    cphrase0 = cp1;
    renew = 1;
  }else if(dura3 > m9l && dura3 < m9h){
    text("9 High D (High G)",x1,y1);
    phrase0 = 9;
    cphrase0 = cp2;
    renew = 1;
  }
  
  //音階に一致したら配列を更新
  if(renew == 1){
    for(int m=phlengt-1;m>0;m--){
      phrase[m] = phrase[m-1];
      cphrase[m] = cphrase[m-1];
    }
    phrase[0] = phrase0;
    cphrase[0] = cphrase0;
  }
  
  //過去の配列を表示
  for(int l=0;l<phlengt;l++){
   text(cphrase[l],120+10*l,460); 
  }
  
  //音階の遷移を読み取る
  for(int l=phlengt-1;l>1;l--){
    if(seqn == 0){
      seq[seqn] = phrase[l];
      seqn++;
    }else if(phrase[l] == phrase[l-1] && phrase[l] != seq[seqn-1]){
      seq[seqn] = phrase[l];
      seqn++;
    }
  }
  
  //音階の遷移を表示
  for(int l=0;l<seqn;l++){
   text(seq[l],120+10*l,480); 
  }
    
  //起動音を鳴らす
  if(flage == 0){
    myChannel.play(1);
    flage = 1;
  }    
    
  ////移動速度の設定
  int mh = 15; //水平面内
  int mv = 20; //上下移動
  int mr = 25; //回転速度

  //キー入力時のみ操作を受け付ける
  if(BSHIFT.pressed()){
    ardrone.takeOff();
    text("TAKE OFF",x2,y2);
  }else if(BCTRL.pressed()){
    ardrone.landing();
    text("LANDING",x2,y2);
  }else if(BD.pressed()){
    ardrone.down(mv);
    text("DOWN",x2,y2);
  }else if(BU.pressed()){
    ardrone.up(mv);
    text("UP",x2,y2);
  }else if(BUP.pressed()){
    ardrone.forward(mh);
    text("FORWARD",x2,y2);
  }else if(BLEFT.pressed()){
    ardrone.goLeft(mh);
    text("GO LEFT",x2,y2);
  }else if(BDOWN.pressed()){
    ardrone.backward(mh);
    text("BACKWARD",x2,y2);
  }else if(BRIGHT.pressed()){
    ardrone.goRight(mh);
    text("GO RIGHT",x2,y2);
  }else if(BL.pressed()){
    ardrone.spinLeft(mr);
    text("SPIN LEFT",x2,y2);
  }else if(BR.pressed()){
    ardrone.spinRight(mr);
    text("SPIN RIGHT",x2,y2);
  }else if(B1.pressed()){
    ardrone.setHorizontalCamera();//前カメラ
    text("Front Camera",x2,y2);
  }else if(B2.pressed()){
    ardrone.setHorizontalCameraWithVertical();//前カメラとお腹カメラ
    text("Front And Belly Camera",x2,y2);
  }else if(B3.pressed()){
    ardrone.setVerticalCamera();//お腹カメラ
    text("Belly Camera",x2,y2);
  }else if(B4.pressed()){
    ardrone.setVerticalCameraWithHorizontal();//お腹カメラと前カメラ
    text("Belly And Front Camera",x2,y2);
  }else if(B5.pressed()){
    ardrone.toggleCamera();//次のカメラ
    text("Next Camera",x2,y2);
  }else if(B8.pressed()){
    ardrone.reset();//Reset
    text("REMOTE RESET",x2,y2);
  }else if(BS.pressed()){
    ardrone.stop();
    text("STOP",x2,y2,x2,y2);
  }else{
    fill(c1);
    //フラグを戻す
    int flagf = 0;
    //フレーズを分析
    for(int l=0;l<seqn-2;l++){
      switch(seq[l]){
        case 1:
          switch(seq[l+1]){
            case 3:
              switch(seq[l+2]){
                case 5:
                  text("Take Off",360,200);
                  ardrone.takeOff();
                  flagf = 1;
                  if(flage == 1){
                    myChannel.loadSound(sririku);
                    myChannel.play(1);
                    flage = 2;
                    flagtime = millis();
                  }
                  break;
              }
              break;
              
            case 4:
              switch(seq[l+2]){
                case 5:
                  text("Go Right",360,230);
                  ardrone.goRight(mh);
                  flagf = 1;
                  if(flage == 1){
                    myChannel.loadSound(smigi);
                    myChannel.play(1);
                    flage = 2;
                    flagtime = millis();
                  }
                  break;
              }
              break;
            
            case 5:
              switch(seq[l+2]){
                case 8:
                  if(altitude < 1300){
                    text("Up",360,200);
                    ardrone.up(mv);
                    flagf = 1;
                    if(flage == 1){
                      myChannel.loadSound(sup);
                      myChannel.play(1);
                      flage = 2;
                    flagtime = millis();
                    }
                  }
                  break;
              }
              break;
          }
          break;
        
        case 3:
          switch(seq[l+1]){
            case 4:
              switch(seq[l+2]){
                case 6:
                  text("spinRight",360,215);
                  ardrone.spinRight(mr);
                  flagf = 1;
                  if(flage == 1){
                    myChannel.loadSound(ssmigi);
                    myChannel.play(1);
                    flage = 2;
                    flagtime = millis();
                  }
                  break;
              }
              break;
          }
          break;
        
          
        case 5:
          switch(seq[l+1]){
            case 3:
              switch(seq[l+2]){
                case 1:
                  text("Landing",360,200);
                  ardrone.landing();
                  flagf = 1;
                  if(flage == 1){
                    myChannel.loadSound(schakuriku);
                    myChannel.play(1);
                    flage = 2;
                    flagtime = millis();
                  }
                  break;
              }
              break;
            
            case 4:
              switch(seq[l+2]){
                case 1:
                  text("Go Left",360,230);
                  ardrone.goLeft(mh);
                  flagf = 1;
                  if(flage == 1){
                    myChannel.loadSound(shidari);
                    myChannel.play(1);
                    flage = 2;
                    flagtime = millis();
                  }
                  break;
              }
              break;
            
            case 6:
              switch(seq[l+2]){
                case 7:
                  text("Forward",360,245);
                  ardrone.forward(mh);
                  flagf = 1;
                  if(flage == 1){
                    myChannel.loadSound(smae);
                    myChannel.play(1);
                    flage = 2;
                    flagtime = millis();
                  }
                  break;
              }
              break;
          }
          break;
          
        case 6:
          switch(seq[l+1]){
            case 4:
              switch(seq[l+2]){
                case 3:
                  text("spinLeft",360,215);
                  ardrone.spinLeft(mr);
                  flagf = 1;
                  if(flage == 1){
                    myChannel.loadSound(sshidari);
                    myChannel.play(1);
                    flage = 2;
                    flagtime = millis();
                  }
                  break;
              }
              break;
          }
          break; 
        
        case 7:
          switch(seq[l+1]){
            case 6:
              switch(seq[l+2]){
                case 5:
                  text("Backward",360,200);
                  ardrone.backward(mh);
                  flagf = 1;
                  if(flage == 1){
                    myChannel.loadSound(sushiro);
                    myChannel.play(1);
                    flage = 2;
                    flagtime = millis();
                  }
                  break;
              }
              break;
          }
          break;
        
        case 8:
          switch(seq[l+1]){
            case 5:
              switch(seq[l+2]){
                case 1:
                  text("Down",360,200);
                  ardrone.down(mv);
                  flagf = 1;
                  if(flage == 1){
                    myChannel.loadSound(sdown);
                    myChannel.play(1);
                    flage = 2;
                    flagtime = millis();
                  }
                  break;
              }
              break;
          }
          break;
      }
    }
    fill(c0);
    
    //一致するフレーズがなければ静止
    if(flagf == 0) ardrone.stop();
  }
  
  //フラグが立っている間は音は鳴らさない
  if(flage == 2){
    if(millis() > flagtime+5000) flage =1;
  }
  
  //様々な変数を元に戻す
  delay(100);
  n = 0;
  dura1 = 0;
  dura2 = 0;
  power1 = 0.0;
  power2 = 0.0;
  strong = thre;
  renew = 0;
  
  for(int l=0;l<phlengt;l++){
    seq[l] = -1; 
  }
  seqn = 0;
  
}
  

public void audioInputData(AudioInput theInput) {
  myfft.getSpectrum(myinput);
}

// clean up Ess before exiting
public void stop() {
  myinput.stop();
  Ess.stop();
  super.stop();
}
