/* Imports for GUI */
import apwidgets.*;
import java.util.ArrayList;

/* Bluetooth imports */
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.widget.Toast;
import android.view.Gravity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import java.util.UUID;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.BufferedWriter;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import java.util.Date;
import java.text.SimpleDateFormat;
import android.bluetooth.BluetoothServerSocket;
import android.bluetooth.BluetoothSocket;
public BluetoothSocket scSocket;

// variables for using bluetooth
boolean inicializacao = true;
boolean foundDevice=false; 
boolean BTisConnected=false; 
ArrayList<PersonalDevice> devices = new ArrayList<PersonalDevice>();
SendReceiveBytes sendReceiveBT;
BufferedWriter writer;
int fileSize = 0;
SimpleDateFormat sdf = new SimpleDateFormat("yyyy.MM.dd hh:mm:ss.S");
public static final int MESSAGE_WRITE = 1;
public static final int MESSAGE_READ = 2;
String readMessage="";

//Obtem o adaptador bluetooth do dispositivo Android
BluetoothAdapter bluetooth = BluetoothAdapter.getDefaultAdapter();

/* Create a BroadcastReceiver that will later be used to 
 receive the names of Bluetooth devices in range. */
BroadcastReceiver myDiscoverer = new myOwnBroadcastReceiver();

/* Create a BroadcastReceiver that will later be used to
 identify if the Bluetooth device is connected */
BroadcastReceiver checkIsConnected = new myOwnBroadcastReceiver();

// More variables for the GUI
APWidgetContainer widgetContainer; 
APToggleButton button;
String[] salaA = {"Sala 117c", //1
                  "Sala 117b", //2
                  "Sala 117a", //3
                  "Sala 115",  //4
                  "Sala 113",  //5
                  "Sala 111",  //6
                  "Sala 109",  //7
                  "Sala 107",  //8
                  "Sala 105",  //9
                  "Sala 103",  //10
                  "Lojinha",   //11
                  "Troféus",   //12
                  "Entrada / NUTAP",  //13     
                  "Sala 128",  //14
                  "Sala 130",  //15
                  "Sala 132",  //16
                  "Sala 134",  //17
                  "Sala 136-DMR", //18 
                  "Baixa Visão-138", //19
                  "Sala 140\nTéc. Cirúrgicas", //20
                  "", //21
                  "Sala 142",       //22
                  "Sala 144-S.Social", //23
                  "",  //24
                  "Sala 146",   //25
                  "Sala 146",   //26
                  "Salas 148 e 150" //27
                  };
String[] salaB = {"Sala 133",  //1
                  "",          //1
                  "Sala 135",  //3
                  "Sala 137",  //4
                  "Sala 139",  //5
                  "",          //6
                  "Sala 141",  //7
                  "Sala 143",  //8
                  "Sala 145",  //9
                  "",          //10
                  "Sala 149",  //11
                  "Escada",    //12
                  "",          //13
                  "DOA",       //14
                  "Psicologia",//15
                  "Sala 106",  //16
                  "Secretaria",//17
                  "Sala 110",  //18  
                  "Baixa Visão-112", //19
                  "Baixa Visão-114", //20 
                  "Sala 116",        //21
                  "Sala 120",   //22
                  "Sala 122",    //23
                  "Sala 124",    //24  
                  "Sala 126-DPMO", //25
                  "", //26
                  "" //27
                }; 
char[] ida   = { 'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','['};
char[] volta = { 'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','{'};
char[] comando={ '1','2','3','4','5' /*,'6' */ };
String mensagemModoTeste = "";                

String[] modosTeste = {"MODO 1", "MODO 2", "MODO 3", "MODO 4", "MODO 5" /*, "MODO 6" */};  //1               
// Screen Resolution of Motorola XOOM 2 = 1280 x 800 pixels.
PFont f;
ArrayList<APToggleButton> botoesSalas;
ArrayList<APToggleButton> botoesModoTeste;
APToggleButton botaoConectar;
String connectedDevice = "";

void setup(){
  orientation(LANDSCAPE);
  f = loadFont("ArialMT-17.vlw");
  textFont(f);
  widgetContainer = new APWidgetContainer(this); //create new container for widgets
  int posX = 20;
  int posY = 60;
  botoesModoTeste = new ArrayList<APToggleButton>();
  for (int n=0; n < modosTeste.length; n++) {
    button = new APToggleButton(posX, posY, 100, 100, modosTeste[n]); 
    botoesModoTeste.add(button);
    posX += 110;
    if (posX >= 1150) {
       posX = 20;
       posY += 110;
    }
    widgetContainer.addWidget(button);
  } 
  botaoConectar = new APToggleButton(posX, posY, 100, 100, "Conectar no Wearable");
  botaoConectar.setTextColor(255,75,75,255);
  widgetContainer.addWidget(botaoConectar);
  
  posX = 20;
  posY = 260;
  botoesSalas = new ArrayList<APToggleButton>();
  for (int n=0; n < salaA.length; n++) {
    button = new APToggleButton(posX, posY, 100, 100, salaA[n]+"\n"+salaB[n]); //create new button from x- and y-pos., width, height and label
    botoesSalas.add(button);
    posX += 110;
    if (posX >= 1150) {
       posX = 20;
       posY += 110;
    }
    widgetContainer.addWidget(button);
  }  
  background(0);
  
  /*SE o Bluetooth NÃO ESTÁ HABILITADO então peço autorização ao usuário para habilitá-lo*/
  if (!bluetooth.isEnabled()) {
    Intent requestBluetooth = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
    startActivityForResult(requestBluetooth, 0);
  }

  /*Se o Bluetooth está habilitado, então registrar um broadcastReceiver para pegar qualquer evento 
   relativo ao Bluetooth (dispositivos encontrados, dados, etc).  */
  if (bluetooth.isEnabled()) {
    // Registro o obj "myDiscoverer" para ser preenchido quando um dispositivo for encontrado (ACTION_FOUND)
    registerReceiver(myDiscoverer, new IntentFilter(BluetoothDevice.ACTION_FOUND));
    // Registro o obj "checkIsConnected" para ser preenchido quando uma conexão for estabelecida (ACTION_ACL_CONNECTED)
    registerReceiver(checkIsConnected, new IntentFilter(BluetoothDevice.ACTION_ACL_CONNECTED));  
    //Se o Bluetooth ainda não está no modo de descoberta, então ligar o modo de descoberta...
    if (!bluetooth.isDiscovering()) {
      bluetooth.startDiscovery();
    }
  }
  
}

void draw(){  
  //background(0); //black background
}

//onClickWidget is called when a widget is clicked/touched
void onClickWidget(APWidget widget){
  if (widget instanceof APToggleButton) {
    background(0);
    APToggleButton b = (APToggleButton) widget;
    if (botoesSalas.contains(b)) {
        for (int n=0; n< botoesSalas.size(); n++){
            APToggleButton b2 = botoesSalas.get(n);
            if (b2 != b) {
                b2.setChecked(false);
            } else {
               // JÁ IDENTIFIQUEI O BOTÃO CLICADO E AGORA MANDO O COMANDO RESPECTIVO.
               if (BTisConnected) {
                 sendReceiveBT.write(stringToBytesArray(String.valueOf(ida[n])));
               }
            }
        }
    }
    
    if (botoesModoTeste.contains(b)) {
       for (int n=0; n< botoesModoTeste.size(); n++){
            APToggleButton b2 = botoesModoTeste.get(n);
            if (b2 != b) {
                b2.setChecked(false);
            } else {
              switch (n) {
                 case 0 : { mensagemModoTeste = "MODO 1: Vista o cinto no voluntário e informe-o que A VIBRAÇÃO no cinto significa que um novo ponto de referência foi encontrado. \nEle pode clicar NO BOTÃO DO CINTO para ouví-lo. "; break; }
                 case 1 : { mensagemModoTeste = "MODO 2: Vista o cinto no voluntário e informe-o que O BEEP do cinto significa que um novo ponto de referência foi encontrado. \nEle pode clicar NO BOTÃO DO CINTO para ouví-lo. "; break; }
                 case 2 : { mensagemModoTeste = "MODO 3: Vista a luva  no voluntário e informe-o que A VIBRAÇÃO na luva significa que um novo ponto de referência foi encontrado. \nEle pode clicar NO BOTÃO DA LUVA para ouví-lo. "; break; }                 
                 case 3 : { mensagemModoTeste = "MODO 4: Vista a luva  no voluntário e informe-o que O BEEP na luva significa que um novo ponto de referência foi encontrado. \nEle pode clicar NO BOTÃO DA LUVA para ouví-lo. "; break; }
                 case 4 : { mensagemModoTeste = "MODO 5: Vista o voluntário APENAS COM OS ÓCULOS. Os pontos de referência serão informados automaticamente para\no voluntário. NÃO HAVERÁ VIBRAÇÃO OU BEEP. "; break; }
                 //case 4 : { mensagemModoTeste = "MODO 5: Vista o voluntário APENAS COM OS ÓCULOS. A vibração na armação dos óculos significa que um novo ponto de referência \nfoi encontrado. Ele pode clicar NO BOTÃO DOS ÓCULOS para ouví-lo. "; break; }
              }
              mensagemModoTeste += "\nLEMBRE-SE DE VERIFICAR SE O WEARABLE ESTÁ CONECTADO AO TABLET ";
              if (BTisConnected) {
                 sendReceiveBT.write(stringToBytesArray(String.valueOf(comando[n])));
              }
            }
        } 
    }
    
    fill(255);
    text(mensagemModoTeste,30,180);
  }
}

/*
 Ao solicitar uma atividade ao SO Android (por exemplo, o pedido de habilitação do bluetooth)
 o evento "onActivityResult" é disparado. Entre os parâmetros do evento está o resultado da solicitação ao SO.
 
 Se o SO (ou o usuário, que neste caso é consultado) autorizar a atividade e a ação for bem sucedida, então o 
 parametro "resultCode" fica igual a "RESULT_OK".
 
 O manipulador de eventos abaixo foi escrito para interceptar o resultado dessa ação de ligar o Bluetooth
 e dar uma mensagem ao usuário confirmando que o Bluetooth foi habilitado ou informando que o Bluetooth 
 PRECISA ser habilitado (no caso de insucesso ou negativa pelo usuário)
 */

@Override
protected void onActivityResult(int requestCode, int resultCode, Intent data) {
  if (requestCode==0) {
    if (resultCode == RESULT_OK) {
      ToastMaster("Bluetooth has been switched ON");
    } 
    else {
      ToastMaster("You need to turn Bluetooth ON !!!");
    }
  }
}


// The Handler that gets information back from the Socket
private final Handler mHandler = new Handler() {
  @Override
    public void handleMessage(Message msg) {
    switch (msg.what) {
    case MESSAGE_WRITE:
      //Do something when writing
      break;
    case MESSAGE_READ:
      //Get the bytes from the msg.obj
      byte[] readBuf = (byte[]) msg.obj;
      // construct a string from the valid bytes in the buffer
      readMessage = new String(readBuf, 0, msg.arg1);
      break;
    }
  }
};

/* This BroadcastReceiver will display discovered Bluetooth devices */
public class myOwnBroadcastReceiver extends BroadcastReceiver {
  ConnectToBluetooth connectBT;

  @Override
    public void onReceive(Context context, Intent intent) {
    String action=intent.getAction();
    //ToastMaster("ACTION:" + action);

    //Notification that BluetoothDevice is FOUND
    if (BluetoothDevice.ACTION_FOUND.equals(action)) {
      //Display the name of the discovered device
      String discoveredDeviceName = intent.getStringExtra(BluetoothDevice.EXTRA_NAME);
      //Display more information about the discovered device
      BluetoothDevice discoveredDevice = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);

      int bondyState=discoveredDevice.getBondState();
      String mybondState;
      switch(bondyState) {
      case 10: 
        mybondState="BOND_NONE";
        break;
      case 11: 
        mybondState="BOND_BONDING";
        break;
      case 12: 
        mybondState="BOND_BONDED";
        break;
      default: 
        mybondState="INVALID BOND STATE";
        break;
      }
      PersonalDevice p = new PersonalDevice(discoveredDeviceName, discoveredDevice.getAddress(), mybondState);
      devices.add(p);
      ToastMaster("Device found = " + p);      

      //Change flag foundDevice to true
      foundDevice=true;

      //Connect to the discovered bluetooth device 
      if (discoveredDeviceName.startsWith("SG")) {
        ToastMaster("Connecting to "+discoveredDeviceName+"...");
        unregisterReceiver(myDiscoverer);
        connectBT = new ConnectToBluetooth(discoveredDevice);
        //Connect to the the device in a new thread
        connectedDevice = discoveredDeviceName;
        new Thread(connectBT).start();
      }
    }

    //Notification if bluetooth device is connected
    if (BluetoothDevice.ACTION_ACL_CONNECTED.equals(action)) {
      ToastMaster("Bluetooth conectado!");
      botaoConectar.setChecked(true);
      while (scSocket==null) {
        //do nothing
      }

      BTisConnected = true;  
      if (scSocket!=null) {
        sendReceiveBT = new SendReceiveBytes(scSocket);
        new Thread(sendReceiveBT).start();
      }
    }
    if (BluetoothDevice.ACTION_ACL_DISCONNECTED.equals(action)) {
      ToastMaster("Bluetooth DESCONECTADO!");
      BTisConnected = false;
      botaoConectar.setChecked(false);
    }
  }
}

public static byte[] stringToBytesArray(String str) {
  byte[] myByte = new byte[str.length()];
  //  myByte = turnOn.getBytes("US-ASCII");
  for (int n=0; n < str.length(); n++) {
    myByte[n] = (byte) str.charAt(n);
  } 
  return myByte;
}

public static byte[] stringToBytesUTFCustom(String str) {
  char[] buffer = str.toCharArray();
  byte[] b = new byte[buffer.length << 1];
  for (int i = 0; i < buffer.length; i++) {
    int bpos = i << 1;
    b[bpos] = (byte) ((buffer[i]&0xFF00)>>8);
    b[bpos + 1] = (byte) (buffer[i]&0x00FF);
  }
  return b;
}

public class ConnectToBluetooth implements Runnable {
  private BluetoothDevice btShield;
  private BluetoothSocket mySocket = null;
  private UUID uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");

  public ConnectToBluetooth(BluetoothDevice bluetoothShield) {
    btShield = bluetoothShield;
    try {
      mySocket = btShield.createRfcommSocketToServiceRecord(uuid);
    }
    catch(IOException createSocketException) {
      //Problem with creating a socket
      aviso("ConnectToBluetooth", "Error with Socket");
    }
  }

  @Override
    public void run() {
    /* Cancel discovery on Bluetooth Adapter to prevent slow connection */
    bluetooth.cancelDiscovery();

    try {
      /*Connect to the bluetoothShield through the Socket. This will block
       until it succeeds or throws an IOException */
      mySocket.connect();
      scSocket=mySocket;
    } 
    catch (IOException connectException) {
      aviso("ConnectToBluetooth", "Error with Socket Connection");
      try {
        mySocket.close(); //try to close the socket
      }
      catch(IOException closeException) {
      }
      return;
    }
  }

  /* Will cancel an in-progress connection, and close the socket */
  public void cancel() {
    try {
      mySocket.close();
    } 
    catch (IOException e) {
    }
  }
}


private class SendReceiveBytes implements Runnable {
  private BluetoothSocket btSocket;
  private InputStream btInputStream = null;
  private OutputStream btOutputStream = null;
  String TAG = "SendReceiveBytes";

  public SendReceiveBytes(BluetoothSocket socket) {
    btSocket = socket;
    try {
      btInputStream = btSocket.getInputStream();
      btOutputStream = btSocket.getOutputStream();
    } 
    catch (IOException streamError) { 
      aviso(TAG, "Error when getting input or output Stream");
    }
  }


  public void run() {
    byte[] buffer = new byte[8192]; // buffer store for the stream
    byte t;
    int bytes = 0; 


    // Keep listening to the InputStream until an exception occurs
    while (true) {
      try {
        // Read from the InputStream
        t = (byte) btInputStream.read();
        if (t != -1) {
          buffer[bytes] = t;
          bytes++;
        }
        // Send the obtained bytes to the UI activity
        if (t == '#') {
          mHandler.obtainMessage(MESSAGE_READ, bytes, -1, buffer).sendToTarget();
          bytes = 0;
          for (int k=0; k < bytes; k++) {
            buffer[k] = '\0';
          }
        }  
      } catch (IOException e) {
        aviso(TAG, "Error reading from btInputStream");
        break;
      }
    }
  }


  /* Call this from the main activity to send data to the remote device */
  public void write(byte[] bytes) {
    try {
      btOutputStream.write(bytes);
    } 
    catch (IOException e) { 
      aviso(TAG, "Error when writing to btOutputStream");
    }
  }


  /* Call this from the main activity to shutdown the connection */
  public void cancel() {
    try {
      btSocket.close();
    } 
    catch (IOException e) { 
      aviso(TAG, "Error when closing the btSocket");
    }
  }
}



/* My ToastMaster function to display a messageBox on the screen */
void ToastMaster(String textToDisplay) {
  Toast myMessage = Toast.makeText(getApplicationContext(), 
  textToDisplay, 
  Toast.LENGTH_SHORT);
  myMessage.setGravity(Gravity.CENTER, 0, 0);
  myMessage.show();
}


public class PersonalDevice {
  public String name;
  public String address;
  public String bondState;

  @Override
    public boolean equals(Object o) {
    boolean result = true;
    if (!(o instanceof PersonalDevice)) {
      result = false;
    } 
    else {
      result = ((PersonalDevice)o).name.equalsIgnoreCase(this.name);
    }
    return result;
  }

  public PersonalDevice(String name, String address, String bondState) {
    this.name = name;
    this.address = address;
    this.bondState = bondState;
  }

  @Override
    public String toString() {
    return this.name+" ["+this.address+" - "+this.bondState+"]";
  }
}

void aviso(String origem, String msg) {
  fill(255);
  text(origem+ " - " + msg, 30, 760);
}

