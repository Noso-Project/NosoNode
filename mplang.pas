unit mpLang;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

Procedure LoadDefLangList();
Procedure CrearArchivoLang();

implementation

uses
  MasterPaskalForm;

Procedure LoadDefLangList();
Begin
DLSL.Clear;
DLSL.Add('1');
DLSL.Add('English');
DLSL.Add('Unknown command: ');                       //0
DLSL.Add('Current Language: ');
DLSL.Add('Lines: ');
DLSL.Add('Language changed to: ');
DLSL.Add('Invalid language number.');
DLSL.Add('Available Languages: ');                   //5
DLSL.Add('Server Excepcion: ');
DLSL.Add('Error receiving line: ');
DLSL.Add('INVALID CLIENT : ');
DLSL.Add('INCOMING CLOSED: OWN CONNECTION');
DLSL.Add('BLACKLISTED FROM: ');                       //10
DLSL.Add('DUPLICATE REJECTED: ');
DLSL.Add('Server full. Unable to keep conection: ');
DLSL.Add('New Connection from: ');
DLSL.Add('Server ENABLED. Listening on port ');
DLSL.Add('Unable to start Server');                   //15
DLSL.Add('Server stopped');
DLSL.Add('Time offset seconds: ');
DLSL.Add('Default language file created.');
DLSL.Add('Update to version sucessfull: ');
DLSL.Add('Error saving block to disk.');               //20
DLSL.Add('Solution for block received and verified: ');
DLSL.Add('CONNECTION REJECTED: INVALID PROTOCOL -> ');
DLSL.Add('Unknown command () in slot: (');
DLSL.Add('New address created : ');
DLSL.Add('Base64 file not found');                     //25
DLSL.Add('Public key file not found.');
DLSL.Add('Signed Verification Ok');
DLSL.Add('Signed Verification FAILED');
DLSL.Add('127.0.0.1 is an invalid server address');
DLSL.Add('Connected TO: ');                           //30
DLSL.Add('Conection lost to ');
DLSL.Add('Conection closed: Time Out Auth -> ');
DLSL.Add('Disconnected.');
DLSL.Add('Connecting...');
DLSL.Add('Connected.');                               //35
DLSL.Add('Updated!');
DLSL.Add('Update file received is wrong.');
DLSL.Add('Update file received is obsolete.');
DLSL.Add('Mining block number: ');
DLSL.Add('BLOCK FOUND! Verified and sent! Block: '); //40
DLSL.Add('Node added.');
DLSL.Add('Node already exists.');
DLSL.Add('Invalid node index.');
DLSL.Add('Node deleted : ');
DLSL.Add(' bots registered.');                       //45
DLSL.Add('Number Type ConnectedTo ChannelUsed LinesOnWait SumHash LBHash Offset ConStatus');
DLSL.Add('GetNodes option is now ');
DLSL.Add('ACTIVE');
DLSL.Add('INACTIVE');
DLSL.Add('Miner ');                                   //50
DLSL.Add(' addresses.');
DLSL.Add('AutoServer option is now ');
DLSL.Add('Autoconnect option is now ');
DLSL.Add('Only the Noso developers can do this.');
DLSL.Add('The specified zip file not exists: ');     //55
DLSL.Add('Can not send the update file.');
DLSL.Add('Update file sent to peers: ');
DLSL.Add('AutoUpdate option is now ');
DLSL.Add('Unable to connect to NTP servers. Check your internet connection');
DLSL.Add('Specified wallet file do not exists.');   //60
DLSL.Add(' Wallet ');
DLSL.Add('Closing wallet');
DLSL.Add('Closed gracefully');
DLSL.Add('Generate new address');
DLSL.Add('Copy address to clipboard');               //65
DLSL.Add('Send coins');
DLSL.Add('Paste destination');
DLSL.Add('Send all');
DLSL.Add('Clear');
DLSL.Add('Send');                                    //70
DLSL.Add('Cancel');
DLSL.Add('Confirm');
DLSL.Add('Transaction details');
DLSL.Add('Headers file received');
DLSL.Add(' (OWN)');                                  //75
DLSL.Add('Receiver : ');
DLSL.Add('Ammount  : ');
DLSL.Add('Concept  : ');
DLSL.Add('Transfers: ');
DLSL.Add('Mined    : ');                             //80
DLSL.Add('Address customization');
DLSL.Add('Address  : ');
DLSL.Add('Alias    : ');
DLSL.Add('Maintenance fee');
DLSL.Add('Interval : ');                             //85
DLSL.Add(' (Address deleted from summary)');
DLSL.Add('Copied to clipboard');
DLSL.Add('Block GENESYS (0) created.');
DLSL.Add('Block builded: ');
DLSL.Add('Block undone: ');                         //90
DLSL.Add('Headers file sent');
DLSL.Add('Requested blocks interval: ');
DLSL.Add('Sent blocks interval: ');
DLSL.Add('Duplicate sender in order');
DLSL.Add('Balance');                                //95
DLSL.Add('Server');
DLSL.Add('Resumen');
DLSL.Add('Connections');
DLSL.Add('Summary');
DLSL.Add('Blocks');                                //100
DLSL.Add('Public IP');
DLSL.Add('Pending');
DLSL.Add('Miner');
DLSL.Add('Hashing');
DLSL.Add('Target');                               //105
DLSL.Add('Reward');
DLSL.Add('Block Time');
DLSL.Add('Block');
DLSL.Add('Time' );
DLSL.Add('Type');                   //110
DLSL.Add('Amount');
DLSL.Add('Method');
DLSL.Add('Price');
DLSL.Add('Total');
DLSL.Add('Status');                         //115
DLSL.Add('Destination');
DLSL.Add('Concept');
DLSL.Add('Address');
DLSL.Add('Not minning');
DLSL.Add('FATAL ERROR');                         //120
DLSL.Add('OpenSSL not found. Program will close inmediately');
DLSL.Add('Updated with ');
DLSL.Add(' peers' );
DLSL.Add('Not mining.');
DLSL.Add('Ready for mine');                         //125
DLSL.Add('Do you want visit the OpenSSL oficial webpage?');
DLSL.Add('Rebuilding until block ');
DLSL.Add('Rebuild block: ');
DLSL.Add(' added to headers');
DLSL.Add('Rebuilding sumary block: ');             //130
DLSL.Add('Sumary rebuilded.');
DLSL.Add('Miner solution invalid?');
DLSL.Add('Failed block verification step: ');
DLSL.Add('The file is not a valid wallet');
DLSL.Add('Addresses imported: ');                  //135
DLSL.Add('No new addreses found.');
DLSL.Add('Invalid address number.');
DLSL.Add('Address 0 is already the default.');
DLSL.Add('New default address: ');
DLSL.Add('Invalid address');                       //140
DLSL.Add('Address already have a custom alias');
DLSL.Add('Alias must have between 5 and 40 chars');
DLSL.Add('Alias can not be a valid address');
DLSL.Add('Insufficient balance');
DLSL.Add('Invalid parameters.');                   //145
DLSL.Add('Invalid destination.');
DLSL.Add('Invalid ammount.');
DLSL.Add('Insufficient funds. Needed: ');
DLSL.Add('From block ');
DLSL.Add(' until ');                               //150
DLSL.Add('And then ');
DLSL.Add('Final supply: ');
DLSL.Add('Coins to group: ');
DLSL.Add('You do not have coins to group.');
DLSL.Add(' wallet translation file');                                        //155
DLSL.Add('Translate each line into the blank line below it');
DLSL.Add('Be careful to respect blank spaces at the beginning and end of each line');
DLSL.Add('Translation file generated.');
DLSL.Add('Something went wrong');
DLSL.Add('Server Already active');                 //160
DLSL.Add('You need add some nodes first');
DLSL.Add('Trying connection to servers');
DLSL.Add('Headers file requested');
DLSL.Add('LastBlock requested from block ');
DLSL.Add(' new address(s).');                                        //165


end;

Procedure CrearArchivoLang();
var
  Archivo : file of string[255];
Begin
LoadDefLangList();
AssignFile(Archivo,LanguageFileName);
rewrite(Archivo);
while DLSL.Count>0 do
   begin
   write(archivo,DLSL[0]);
   DLSL.Delete(0);
   end;
Closefile(Archivo);
LoadDefLangList();
End;

END. // END UNIT

