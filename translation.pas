unit translation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

resourcestring
  rs0001 = 'TimeOut reading from slot: %s';
  rs0002 = 'Error Reading lines from slot: %s';
  rs0003 = 'Receiving headers';
  rs0004 = 'Error Receiving headers from %s (%s)';
  rs0005 = 'Headers file received: %s';
  rs0006 = 'Receiving blocks';
  rs0007 = 'Error Receiving blocks from %s (%s)';
  rs0008 = 'Error sending outgoing message: %s';
  rs0009 = 'ERROR: Deleting OutGoingMessage-> %s';
  rs0010 = 'Auto restart enabled';
  rs0011 = 'BAT file created';
  rs0012 = 'Crash info file created';
  rs0013 = 'Data restart file created';
  rs0014 = 'All forms closed';
  rs0015 = 'Outgoing connections closed';
  rs0016 = 'Node server closed';
  rs0017 = 'Closing pool server...';
  rs0018 = 'Pool server closed';
  rs0019 = 'Pool members file saved';
  rs0020 = 'Noso launcher executed';
  rs0021 = 'Blocks received up to %s';
  rs0022 = '✓ Data directory ok';
  rs0023 = '✓ GUI initialized';
  rs0024 = '✓ My data updated';
  rs0025 = '✓ Miner configuration set';
  rs0026 = '✓ %s languages available';
  rs0027 = 'Wallet %s%s';
  rs0028 = '✓ %s CPUs found';
  rs0029 = 'Noso session started';



{
ConsoleLinesadd(format(rs,[]));
}
implementation

end.

