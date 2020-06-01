classdef ATEC302 < handle
    
 
    properties (Constant)
        
        
        cCONNECTION_SERIAL = 'serial'
        cCONNECTION_TCPIP = 'tcpip'
        cCONNECTION_TCPCLIENT = 'tcpclient'      
        
    end
    
    properties (SetAccess = private)
        
        % tcpclient config
        % --------------------------------
        % {char 1xm} tcp/ip host
        cHost = '192.168.20.36'
        
        % {uint16 1x1} tcpip port NPort requires a port of 4001 when in
        % "TCP server" mode
        u16Port = uint16(4001)
        
        
        % serial config
        % --------------------------------
        u16BaudRate = 9600;
        cPort = 'COM1'
        cTerminator = '';
        
        cConnection
        
        % {double 1x1} - timeout of MATLAB {serial} - amount of time it will
        % wait for a response before aborting.  
        dTimeout = 2;
        lShowWaitingForBytes = false;
        
        comm
        
        % {logical 1x1} true when waiting for a response. 
        lIsBusy = false
        
        % {double 1x1} storage of the last successfully read value
        dSetValue = 10;
        % {double 1x1} storage of the last successfully read temp
        dTemperature = 15;
        
        % {char 1x4} storage of the last successfully read enabled state
        cxEnabledState = '0000' 
    end
    
    
    methods
        
        function this = ATEC302(varargin)
            
            
            this.cConnection = this.cCONNECTION_TCPCLIENT;
            
            for k = 1 : 2: length(varargin)
                this.msg(sprintf('passed in %s', varargin{k}));
                if this.hasProp( varargin{k})
                    this.msg(sprintf('settting %s', varargin{k}));
                    this.(varargin{k}) = varargin{k + 1};
                end
            end
            
            
        end
        
        function delete(this)
            this.comm = [];
        end
        
        
        function init(this)
            
            switch this.cConnection
                case this.cCONNECTION_SERIAL
                    try
                        this.msg('init() creating serial instance');
                        this.comm = serial(this.cPort);
                        this.comm.BaudRate = this.u16BaudRate;
                        this.comm.Terminator = this.cTerminator;
                        % this.comm.InputBufferSize = this.u16InputBufferSize;
                        % this.comm.OutputBufferSize = this.u16OutputBufferSize;
                    catch ME
                        rethrow(ME)
                    end
              case this.cCONNECTION_TCPCLIENT
                    try
                       this.msg('init() creating tcpclient instance');
                       this.comm = tcpclient(this.cHost, this.u16Port);
                    catch ME
                        rethrow(ME)
                    end
            end
            
            this.clearBytesAvailable();
        end
        
        % Reads all available bytes from the input buffer
        function clearBytesAvailable(this)

            this.lIsBusy = true;
            while this.comm.BytesAvailable > 0
                cMsg = sprintf(...
                    'clearBytesAvailable() clearing %1.0f bytes\n', ...
                    this.comm.BytesAvailable ...
                );
                fprintf(cMsg);
                bytes = read(this.comm, this.comm.BytesAvailable);
            end
            this.lIsBusy = false;
        end
        
        % Returns {logical} true if output is off
        function lReturn = getIsDisabled(this)
            lReturn = strcmpi(this.getEnabledState(), '0000');
        end 
        
        
        % Returns {logical} true if in single
        % point temp control (SPON)
        function lReturn = getIsEnabledSPON(this)
            lReturn = strcmpi(this.getEnabledState(), '0004');
        end 
        
        % Sets ENAB to "off"
        function disable(this)
            
            % convert to hex (force 4 characters)
            cxVal = '0000';
            
            % crate 8x2 char array of 8 hex bytes (64-bit)
            cxId = '01';
            cxFcn = '06';
            cxAddr = ['00'; '02'];
            
            cCmd = [cxId; cxFcn; cxAddr; cxVal(1:2); cxVal(3:4)];
                        
            % Careful here - hex2dec returns type double
            % need to cast as uint8 befor sending to write
            u8Msg = hex2dec(cCmd); % {double 6 x 1}
            u8Msg = this.append_crc(u8Msg); %{double 8 x 1}
            
            this.write(uint8(u8Msg));
            
        end
        
        % Sets ENAB to single point temp control (SPON)
        function enableSPON(this)
            
            % convert to hex (force 4 characters)
            cxVal = '0004';
            
            % crate 8x2 char array of 8 hex bytes (64-bit)
            cxId = '01';
            cxFcn = '06';
            cxAddr = ['00'; '02'];
            
            cCmd = [cxId; cxFcn; cxAddr; cxVal(1:2); cxVal(3:4)];
                        
            % Careful here - hex2dec returns type double
            % need to cast as uint8 befor sending to write
            u8Msg = hex2dec(cCmd); % {double 6 x 1}
            u8Msg = this.append_crc(u8Msg); %{double 8 x 1}
            
            this.write(uint8(u8Msg));
            
        end
        
        % Returns four element char array of hex characters [0-9a-f]
        % with one of the following values based on the enabled state of
        % the hardware
        % x0000 / OFF (Turn off output)
        % x0001 / AT1 (auto-tune at SV)
        % x0002 / AT2 (auto-tune at 90% of SV )
        % x0003 / MPWR (Manual set duty cyl)
        % x0004 / SPON (Single Temp point ctrl)
        % x0005 / PROG (Run Programmable temp profile)
        % x0006 / HOLD (Hold Temp during prog profile run )
        
        function cxData = getEnabledState(this)
            
            % crate 8x2 char array of 8 hex bytes (64-bit)

            cxId = '01';
            cxFcn = '03'; % read 
            cxAddr = ['00'; '02']; % 
            cxCount = ['00'; '01']; % read one data
            % cxCrc = ['cc'; 'cc'];
            
            cCmd = [cxId; cxFcn; cxAddr; cxCount];
            
            % Careful here - hex2dec returns type double
            % need to cast as uint8 befor sending to write
            u8Msg = hex2dec(cCmd); % {double 6 x 1}
            u8Msg = this.append_crc(u8Msg); %{double 8 x 1}
            
            this.write(uint8(u8Msg));
            
            if this.waitForBytesAvailable(8)
            
                % {uint8 mx1} read returns {uint8 8x1} 8-byte response
                u8Response = read(this.comm, 8);

                % Bytes 5 and 6 of the response contain the temperature data
                u8Data = u8Response(5:6);

                % Convert each 1-byte int to hex representation
                % (force two hex characters for each)
                cxData = dec2hex(u8Data, 2);

                % combine into a single 2-byte hex value, e.g., x011F 
                cxData = reshape(cxData', 1, 4);
                
                this.cxEnabledState = cxData;

            else
                this.msg('getEnabledState() returning last successfully read value');
                cxData = this.cxEnabledState;
            end
            
        end
        
        % Write a new setpoint to the hardware.  This is reverred to as the
        % Set Value (SV) in the manual, so this class follows that
        % nomenclature
        % @param {double 1x1} dValC - degrees C
        function setSetValue(this, dValC)
            
            % multiply the value by 10 and convert to 16-bit int
            u16Val = uint16(dValC * 10);
            
            % convert to hex (force 4 characters)
            cxVal = dec2hex(u16Val, 4);
            
            % reshape into a {2x2 char array}
            % cxVal = reshape(cxVal, 2, 2);
            
            % crate 8x2 char array of 8 hex bytes (64-bit)
            cxId = '01';
            cxFcn = '06';
            cxAddr = ['00'; '00'];
            
            cCmd = [cxId; cxFcn; cxAddr; cxVal(1:2); cxVal(3:4)];
                        
            % Careful here - hex2dec returns type double
            % need to cast as uint8 befor sending to write
            u8Msg = hex2dec(cCmd); % {double 6 x 1}
            u8Msg = this.append_crc(u8Msg); %{double 8 x 1}
            
            this.write(uint8(u8Msg));
            
        end
        
        % Returns the setpoint in cegrees C
        % @param {double 1x1} dValC - degrees C
        function d = getSetValue(this)
                        
            % crate 8x2 char array of 8 hex bytes (64-bit)

            cxId = '01';
            cxFcn = '03';
            cxAddr = ['10'; '01'];
            cxCount = ['00'; '01'];
            % cxCrc = ['cc'; 'cc'];
            
            cCmd = [cxId; cxFcn; cxAddr; cxCount];
            
            % Careful here - hex2dec returns type double
            % need to cast as uint8 befor sending to write
            u8Msg = hex2dec(cCmd); % {double 6 x 1}
            u8Msg = this.append_crc(u8Msg); %{double 8 x 1}
            
            this.write(uint8(u8Msg));
            
            if this.waitForBytesAvailable(8)
            
                % {uint8 mx1} read returns {uint8 8x1} 8-byte response
                u8Response = read(this.comm, 8);

                % Bytes 5 and 6 of the response contain the temperature data
                u8Data = u8Response(5:6);

                % Convert each 1-byte int to hex representation
                % (force two hex characters for each)
                cxData = dec2hex(u8Data, 2);

                % combine into a single 2-byte hex value, e.g., x011F 
                cxData = reshape(cxData', 1, 4);

                % convert to decimal
                % and divide by 10 since hardware returns a 0.1C resolution value
                % multiplied by 10
                d = hex2dec(cxData) / 10;
                
                % update last good value
                this.dSetValue = d;
            else
                this.msg('getSetValue() returning last successfully read value');
                d = this.dSetValue;
            end
            
            
        end
        
        % Returns the current temperature in C
        function d = getTemperature(this)
            
            % crate 8x2 char array of 8 hex bytes (64-bit)

            cxId = '01';
            cxFcn = '03';
            cxAddr = ['10'; '00'];
            cxCount = ['00'; '01'];
            % cxCrc = ['cc'; 'cc'];
            
            cCmd = [cxId; cxFcn; cxAddr; cxCount];
            
            u8Msg = hex2dec(cCmd); % {uint8 6 x 1}
            u8Msg = this.append_crc(u8Msg); %{uint8 8 x 1}
            
            try
                this.write(uint8(u8Msg));
            catch mE
                this.msg('getTemperture() caught error when wrapping this.write() call');
            end
                            
            if this.waitForBytesAvailable(8)
            
                % {uint8 mx1} read returns {uint8 8x1} 8-byte response
                u8Response = read(this.comm, 8);

                % Bytes 5 and 6 of the response contain the temperature data
                u8Data = u8Response(5:6);

                % Convert each 1-byte int to hex representation
                % (force two hex characters for each)
                cxData = dec2hex(u8Data,2);

                % combine into a single 2-byte hex value, e.g., x011F 
                cxData = reshape(cxData', 1, 4);

                % convert to decimal
                % and divide by 10 since hardware returns a 0.1C resolution value
                % multiplied by 10
                d = hex2dec(cxData) / 10;
                
                % update last good value
                this.dTemperature = d;
                
            else
                this.msg('getTemperature() returning last successfully read value');
                d = this.dTemperature;
            end
        end
        
        
        
        
        
        % {uint8 m x 1} list of bytes in decimal including terminator
        function write(this, u8Data)
            
            if ~isa(u8Data, 'uint8')
                error('u8Data must be uint8 data type');
            end
            
            % Add terminator
            % u8Data = [u8Data; 10; 13];
            
            % Echo each byte in HEX
            % fprintf('atec.atec302.write() hex bytes:');
            % dec2hex(double(u8Data))
            
            switch this.cConnection
                case {this.cCONNECTION_SERIAL, this.cCONNECTION_TCPIP}
                     fwrite(this.comm, u8Data);
                case this.cCONNECTION_TCPCLIENT
                    write(this.comm, u8Data);
                     % write(this.comm, [u8Data; 13]); % 13 is the terminator
            end
        end
        
        
    end
    
    
    methods (Access = protected)
        
        % From https://www.mathworks.com/matlabcentral/fileexchange/11738-append-crc-for-modbus
        % Appends the crc (Low byte, high byte) to message for modbus
        % communication. Message is an array of bytes. Developed for (but not
        % limmited to) use with a watlow 96 controller.
        % @param {int8 1xm} message - list of bytes
        function amsg = append_crc(this, message)
            
            N = length(message);
            crc = hex2dec('ffff');
            polynomial = hex2dec('a001');

            for i = 1:N
                crc = bitxor(crc,message(i));
                for j = 1:8
                    if bitand(crc,1)
                        crc = bitshift(crc,-1);
                        crc = bitxor(crc,polynomial);
                    else
                        crc = bitshift(crc,-1);
                    end
                end
            end

            lowByte = bitand(crc,hex2dec('ff'));
            highByte = bitshift(bitand(crc,hex2dec('ff00')),-8);

            amsg = message;
            amsg(N+1) = lowByte;
            amsg(N+2) = highByte;
            
        end
        
        function msg(~, cMsg)
            cTimestamp = datestr(datevec(now), 'yyyymmdd-HHMMSS', 'local');
            fprintf('%s: ATEC302 %s\n', cTimestamp, cMsg);
        end
        
        function l = hasProp(this, c)
            
            l = false;
            if ~isempty(findprop(this, c))
                l = true;
            end
            
        end
        
        % Blocks execution until the serial has provided BytesAvailable
        % @param {int 1x1} the number of bytes to wait for
        % @return {logical 1x1} returns true if found the expected number
        % of bytes before the timeout
        function lSuccess = waitForBytesAvailable(this, dBytesExpected)
            
                        
            if this.lShowWaitingForBytes
                cMsg = sprintf(...
                    'waitForBytesAvailable(%1.0f)', ...
                    dBytesExpected ...
                );
                this.msg(cMsg);
            end
                  
            tic
            while this.comm.BytesAvailable < dBytesExpected
                
                if this.lShowWaitingForBytes
                    cMsg = sprintf(...
                        'waitForBytesAvailable() ... %1.0f of %1.0f expected bytes are currently available', ...
                        this.comm.BytesAvailable, ...
                        dBytesExpected ...
                    );
                    this.msg(cMsg);
                end
                
                if (toc > this.dTimeout)
                    cMsg = sprintf(...
                        'waitForByetesAvailable() timeout (> %1.1f sec) did not reach expected BytesAvailable (%1.0f)', ...
                        this.dTimeout, ...
                        dBytesExpected ...
                    );
                    lSuccess = false;
                    this.msg(cMsg);
                    return
                end
            end
            
            lSuccess = true;
            
        end
        
    end
    
    
    
    
end

