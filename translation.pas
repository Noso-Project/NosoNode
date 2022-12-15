unit translation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

resourcestring
  //Master form
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
  rs0027 = 'Node %s%s';
  rs0028 = '✓ %s CPUs found';
  rs0029 = 'Noso session started';
  rs0030 = 'Closing wallet';
  rs0031 = 'POOL: Error trying close a pool client connection (%s)';
  rs0032 = 'POOL: Error sending message to miner (%s)';
  rs0033 = 'POOL: Rejected not registered user';
  rs0034 = 'Pool: Error registering a ping-> %s';
  rs0035 = 'Pool solution verified!';
  rs0036 = 'Pool solution FAILED at step %s';

  rs0038 = 'POOL: Unexpected command from: %s -> %s';
  rs0039 = 'POOL: Status requested from %s';
  rs0040 = 'Pool: closed incoming %s (%s)';
  rs0041 = 'Pool: Error inside MinerJoin (%s) -> %s';
  rs0042 = 'SERVER: Error trying close a server client connection (%s)';
  rs0043 = 'SERVER: Received a line from a client without and assigned slot: %s';
  rs0044 = 'SERVER: Timeout reading line from connection';
  rs0045 = 'SERVER: Can not read line from connection %s (%s)';
  rs0046 = 'SERVER: Server error receiving headers file (%s)';
  rs0047 = 'Headers file received: %s';
  rs0048 = 'SERVER: Server error receiving block file (%s)';
  rs0049 = 'SERVER: Error creating stream from headers: %s';
  rs0050 = 'Headers file sent to: %s';
  rs0051 = 'SERVER: Error sending headers file (%s)';
  rs0052 = 'SERVER: BlockZip send to %s: %s';
  rs0053 = 'SERVER: Error sending ZIP blocks file (%s)';
  rs0054 = 'SERVER: Error adding received line (%s)';
  rs0055 = 'SERVER: Got unexpected line: %s';
  rs0056 = 'SERVER: Timeout reading line from new connection';
  rs0057 = 'SERVER: Can not read line from new connection (%s)';
  rs0058 = 'SERVER: Invalid client -> %s';
  rs0059 = 'SERVER: Own connected';
  rs0060 = 'SERVER: Duplicated connection -> %s';
  rs0061 = 'New Connection from: %s';
  rs0062 = 'SERVER: Closed unhandled incoming connection -> %s';
  rs0063 = 'Stake size';
  rs0064 = 'MNs earnings';
  rs0065 = 'PoS earnings';
  rs0066 = 'Rebuilding my transactions...';
  rs0067 = '✓ My transactions rebuilded';
  rs0068 = '✓ My transactions grid updated';
  rs0069 = '✓ Launcher file deleted';
  rs0070 = '✓ Restart file deleted';
  rs0071 = 'Checking last release available...';
  rs0072 = '✗ Failed connecting with project repo';
  rs0073 = '✓ Running last release version';
  rs0074 = '✗ New version available on project repo';
  rs0075 = '✓ Running a development version';
  rs0076 = 'Start server';
  rs0077 = 'Stop server';
  rs0078 = 'Connect';
  rs0079 = 'Disconnect';
  rs0080 = 'You can not test while server is active';
  rs0081 = 'Invalid sign address';
  rs0082 = 'Funds address do not owns enough coins';
  rs0083 = 'You need update the wallet';
  rs0084 = 'Not valid ASCII message received: %s';
  rs0085 = 'Receiving summary file';
  rs0086 = 'Error Receiving sumary from %s (%s)';
  rs0087 = 'Sumary file received: %s';
  rs0088 = '✓ My GVTs grid updated';
  rs0089 = 'Receiving GVTs file';
  rs0090 = 'Error Receiving GVTs from %s (%s)';
  rs0091 = 'SERVER: Error creating stream from GVTs: %s';
  //mpGUI
  rs0500 = 'Noso Launcher';
  rs0501 = 'Destination';
  rs0502 = 'Amount';
  rs0503 = 'Reference';
  rs0504 = 'Balance';
  rs0505 = 'Server';
  rs0506 = 'Connections';
  rs0507 = 'Headers';
  rs0508 = 'Summary';
  rs0509 = 'LastBlock';
  rs0510 = 'Blocks';
  rs0511 = 'Pending';
  rs0512 = 'Invalid language: %s';
  rs0513 = 'Wallet restart needed';
  rs0514 = 'Address';
  rs0515 = 'Balance';
  rs0516 = 'Masternodes: (%d) %s';
  rs0517 = '(%d)  %d/%s';
  rs0518 = 'Next Miner';
  rs0519 = 'Best Hash';
  //mpDisk
  rs1000 = 'Processing block %d (%d %%)';
  rs1001 = '----- ERROR ----'+Slinebreak+'Block: %d';
  rs1002 = 'Wrong block hash'+SlineBreak+'File: %s'+Slinebreak+'Headers: %s';
  rs1003 = 'File not found: %s';
  rs1004 = 'Wrong summary hash'+SlineBreak+'Summary: %s'+Slinebreak+'Headers: %s';
  //mpParser
  rs1501 = 'Invalid address';
  rs1502 = 'You can not do it while pool is active.';
  rs1503 = 'Totals: %d connections, %d IPs';
  rs1504 = 'Address do not exists in wallet.';
  rs1505 = 'Keys pasted to clipboard.';
  //mpred
  rs2000 = 'Sign address not valid';
  rs2001 = 'Wallet not updated';
  rs2002 = '*****CRITICAL*****'+Slinebreak+'Error inside VerifyConnectionStatus'+Slinebreak+'%s'+'*****CRITICAL*****';
  rs2003 = 'Sumary file requested';
  //mpcrypto
  rs2501 = '*****CRITICAL*****'+Slinebreak+'Error type 3 on crypto thread: %s'+Slinebreak+'*****CRITICAL*****';
  rs2502 = '*****CRITICAL*****'+Slinebreak+'Error type 4 on crypto thread: %s'+Slinebreak+'*****CRITICAL*****';
  rs2503 = '*****CRITICAL*****'+Slinebreak+'Error type 5 on crypto thread: %s'+Slinebreak+'*****CRITICAL*****';
  rs2504 = '*****CRITICAL*****'+Slinebreak+'Error type 6 on crypto thread: %s'+Slinebreak+'*****CRITICAL*****';
  rs2505 = '*****CRITICAL*****'+Slinebreak+'Error type 7 on crypto thread: %s'+Slinebreak+'*****CRITICAL*****';
{
ConsoleLinesadd(format(rs,[]));
}
implementation

END.

