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
import processing.core.PImage;

public BluetoothSocket scSocket;

// variables for using bluetooth
boolean inicializacao = true;
boolean foundDevice=false; 
boolean BTisConnected=false; 
PImage  backgroundImg;
ArrayList<PersonalDevice> devices = new ArrayList<PersonalDevice>();
SendReceiveBytes sendReceiveBT;
BufferedWriter writer;
int fileSize = 0;
SimpleDateFormat sdf = new SimpleDateFormat("yyyy.MM.dd hh:mm:ss.S");
public static final int MESSAGE_WRITE = 1;
public static final int MESSAGE_READ = 2;
String readMessage="";

//Obtem o adaptador bluetooth do dispositivo Android
BluetoothAdapter bluetooth = BluetoothAdapter.getDefaultAdapter(); //  getSystemService(String) with BLUETOOTH_SERVICE. 
//BluetoothAdapter bluetooth = BluetoothAdapter.getSystemService(BLUETOOTH_SERVICE);

/* Create a BroadcastReceiver that will later be used to 
 receive the names of Bluetooth devices in range. */
BroadcastReceiver myDiscoverer = new myOwnBroadcastReceiver();

/* Create a BroadcastReceiver that will later be used to
 identify if the Bluetooth device is connected */
BroadcastReceiver checkIsConnected = new myOwnBroadcastReceiver();

// More variables for the GUI
APWidgetContainer widgetContainer; 
APToggleButton button;
String[] salaA = {
  " ",  //1,  M1
  " ",  //2,  M2 
  " ",  //3,  P1
  " ",  //4,  B1
  " ",  //5,  B2
  " ",  //6,  P2
  " ", //7,  CO1
  " ", //8,  CO2
  " ", //9,  BN1
  " ", //10, ES1
  " ", //11, PV1
  " ", //12, REL
  " ",  //13, BU
  " ", //14, BNC
  " ", //15, ES2
  " ", //16, BN2
  " ", //17, EL1
  " ", //18, EL2
  " ", //19, PV2
  " "  //20  PV3
};

//                 M1         M2        P1       B1        B2       P2         CO1       CO2          BN1        ES1        PV1        REL      BU         chapeu     ES2        BN2         EL1        EL2         PV2         PV3
int[][] xyINI = { {55, 491}, {212,491},{303,634},{471,491},{633,491},{714,634},{860,480},{972, 480}, {805,391}, {676,172},{801,135},{850,176}, {959, 176}, {912,298},{1080,172},{984, 391}, {809,645}, {973, 645}, {916, 135}, {1007, 135}};
int[][] xyFIM = { {127,545}, {284,545},{380,690},{543,545},{705,545},{791,690},{928,540},{1040,540}, {871,464}, {786,234},{862,175},{918,261}, {1024,261}, {977,380},{1183,234},{1060,464}, {896,700}, {1060,700}, {977, 175}, {1068, 175}};
char[] ida   = { 
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '['
};
String mensagemModoTeste = "";                

// Screen Resolution of Motorola XOOM 2 = 1280 x 800 pixels.
// Screen Resolution of Motorola Moto g = 1280 x 720 pixels
PFont f;
ArrayList<APToggleButton> botoesSalas;
APToggleButton botaoConectar;
String connectedDevice = "";

void setup() {
  // GUI COMMANDS
  orientation(LANDSCAPE);
  f = loadFont("ArialMT-17.vlw");
  backgroundImg = loadImage("planta_ibc_3andar_full.png");
  textFont(f);
  widgetContainer = new APWidgetContainer(this); //create new container for widgets
  int posX = 20;
  int posY = 20;

  botaoConectar = new APToggleButton(posX, posY, 200, 200, "Conexão Bluetooth\nOFF");
  botaoConectar.setTextColor(255, 75, 75, 255);
  widgetContainer.addWidget(botaoConectar);

  posX = 0;
  posY = 0;
  int tamX = 0;
  int tamY = 0;
  botoesSalas = new ArrayList<APToggleButton>();

  for (int n=0; n < salaA.length; n++) {
    posX   = xyINI[n][0];
    posY   = xyINI[n][1];
    tamX   = xyFIM[n][0] - posX;
    tamY   = xyFIM[n][1] - posY;
    button = new APToggleButton(posX, posY, tamX, tamY, salaA[n]); //create new button from x- and y-pos., width, height and label
    botoesSalas.add(button);
    posX += 110;
    if (posX >= 1150) {
      posX = 20;
      posY += 110;
    }
    widgetContainer.addWidget(button);
  }  

  background(0);

  //BLUETOOTH COMMANDS

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

void draw() {  
  image(backgroundImg, 0, 0);
}

//onClickWidget is called when a widget is clicked/touched
void onClickWidget(APWidget widget) {
  if (widget instanceof APToggleButton) {
    background(0);
    APToggleButton b = (APToggleButton) widget;

    if (botoesSalas.contains(b)) {
      for (int n=0; n< botoesSalas.size(); n++) {
        APToggleButton b2 = botoesSalas.get(n);
        if (b2 != b) {
          b2.setChecked(false);
        } 
        else {
          // JÁ IDENTIFIQUEI O BOTÃO CLICADO E AGORA MANDO O COMANDO RESPECTIVO.
          if (BTisConnected) {
            try {
              sendReceiveBT.write(stringToBytesArray(String.valueOf(ida[n])));
            } 
            catch (Exception e) {
            }
          }
        }
      }
    }
  }   
  //fill(255);
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
    if (context == null || intent == null) {
      return;
    }
    try {
      String action=intent.getAction();

      //Notification that BluetoothDevice is FOUND
      if (BluetoothDevice.ACTION_FOUND.equals(action)) {
        //Display the name of the discovered device
        BluetoothDevice discoveredDevice = null; 
        String discoveredDeviceName = "unknown";
        try {
          System.out.print("Dispositivo encontrado: ");
          discoveredDevice = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);  
          System.out.println(discoveredDevice);
          if (!discoveredDevice.getAddress().equalsIgnoreCase("20:13:08:19:16:45")) { //Se não for os SmartGlasses, return
              return;
          } 
          discoveredDeviceName = discoveredDevice.getName();
          //System.out.println("Address:" + discoveredDevice.getAddress());
          System.out.println("Nome: "+discoveredDeviceName);
        } 
        catch (Exception e) {
          System.out.println(e);
          return;
        }
        System.out.println(discoveredDeviceName);
        //Display more information about the discovered device
        //BluetoothDevice discoveredDevice = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE); 
        System.out.println("BluetoothDevice discovered");
        int bondyState=discoveredDevice.getBondState();
        System.out.println(bondyState);
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
        System.out.println("criando objeto PersonalDevice p");
        PersonalDevice p = new PersonalDevice(discoveredDeviceName, discoveredDevice.getAddress(), mybondState);
        System.out.println("Adicionando na lista...");
        devices.add(p);
        aviso("Bluetooth: ", "Device found = " + p);      

        //Change flag foundDevice to true
        foundDevice=true;

        //Connect to the discovered bluetooth device 
        if (discoveredDeviceName.startsWith("SG")) {
          aviso("Bluetooth", "Connecting to "+discoveredDeviceName+"...");
          unregisterReceiver(myDiscoverer);
          connectBT = new ConnectToBluetooth(discoveredDevice);
          //Connect to the the device in a new thread
          connectedDevice = discoveredDeviceName;
          new Thread(connectBT).start();
        }
      }

      //Notification if bluetooth device is connected
      if (BluetoothDevice.ACTION_ACL_CONNECTED.equals(action)) {
        aviso("Bluetooth", "Bluetooth conectado!");
        botaoConectar.setChecked(true);
        botaoConectar.setText("Conexão Bluetooth\nON");
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
        botaoConectar.setText("Conexão Bluetooth\nOFF");
        bluetooth.startDiscovery();
      }
    } 
    catch (RuntimeException re) {
      System.out.println(re.getMessage());
    }
  }
}

public static byte[] stringToBytesArray(String str) {
  if (str == null) {
    return null;
  } 
  else if (str.isEmpty()) {
    return null;
  }
  byte[] myByte = new byte[str.length()];
  //  myByte = turnOn.getBytes("US-ASCII");
  for (int n=0; n < str.length(); n++) {
    myByte[n] = (byte) str.charAt(n);
  } 
  return myByte;
}

public static byte[] stringToBytesUTFCustom(String str) {
  if (str == null) {
    return null;
  } 
  else if (str.isEmpty()) {
    return null;
  }
  char[] buffer = str.toCharArray();
  byte[] b = null;
  try {
    b = new byte[buffer.length << 1];
    for (int i = 0; i < buffer.length; i++) {
      int bpos = i << 1;
      b[bpos] = (byte) ((buffer[i]&0xFF00)>>8);
      b[bpos + 1] = (byte) (buffer[i]&0x00FF);
    }
  } 
  catch (Exception e) {
    System.out.println("Erro ao ler bytes... "+e.getMessage());
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
    catch(Exception e) {
      //Problem with creating a socket
      aviso("ConnectToBluetooth", "Error with Socket: "+e.getMessage());
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
    catch (Exception connectException) {
      aviso("ConnectToBluetooth", "Error with Socket Connection: "+connectException.getMessage());
      try {
        mySocket.close(); //try to close the socket
      }
      catch(Exception closeException) {
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
    } 
    catch (Exception e) {
      aviso(TAG, "Error when getting inputStream: "+e.getMessage());
    }
    try {
      btOutputStream = btSocket.getOutputStream();
    } 
    catch (Exception e) {
      aviso(TAG, "Error when getting outputStream: "+e.getMessage());
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
      } 
      catch (IOException e) {
        aviso(TAG, "Error reading from btInputStream: "+e.getMessage());
        break;
      }
    }
  }


  /* Call this from the main activity to send data to the remote device */
  public void write(byte[] bytes) {
    try {
      btOutputStream.write(bytes);
    } 
    catch (Exception e) { 
      aviso(TAG, "Error when writing to btOutputStream: "+e.getMessage());
      /*background(0);
       setup();*/
    }
  }


  /* Call this from the main activity to shutdown the connection */
  public void cancel() {
    try {
      btSocket.close();
    } 
    catch (Exception e) { 
      aviso(TAG, "Error when closing the btSocket: "+e.getMessage());
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
  stroke(0);          // Setting the outline (stroke) to black
  fill(255);          // Setting the interior of a shape (fill) to grey 
  rect(20, 675, 1150, 780); // Drawing the rectangle
  fill(0);
  text(origem+ " - " + msg, 30, 700);
}

