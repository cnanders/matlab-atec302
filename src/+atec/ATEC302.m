classdef ATEC302 < handle
    
 
    properties (Constant)
        
        
        cCONNECTION_SERIAL = 'serial'
        cCONNECTION_TCPIP = 'tcpip'
        cCONNECTION_TCPCLIENT = 'tcpclient'      
        
    end
    
    properties (SetAccess = private)
        
        % tcpip config
        % --------------------------------
        % {char 1xm} tcp/ip host
        cIp = '192.168.0.2'
        
        % {uint16 1x1} tcpip port NPort requires a port of 4001 when in
        % "TCP server" mode
        u16Port = uint16(4001)
        
        
        % serial config
        % --------------------------------
        u16BaudRate = 19200;
        cPort = 'COM1'
        cTerminator = '';
        
        cConnection
        
        % {double 1x1} - timeout of MATLAB {serial} - amount of time it will
        % wait for a response before aborting.  
        dTimeout = 10;
        lShowWaitingForBytes = false;
        
        comm
        
    end
    
    methods
        
        function this = ATEC302(varargin)
            
            
            this.cConnection = this.cCONNECTION_SERIAL;
            
            for k = 1 : 2: length(varargin)
                this.msg(sprintf('passed in %s', varargin{k}));
                if this.hasProp( varargin{k})
                    this.msg(sprintf('settting %s', varargin{k}));
                    this.(varargin{k}) = varargin{k + 1};
                end
            end
            
            
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
            end
        end
        
        % Write a new setpoint to the hardware
        % @param {double 1x1} dValC - degrees C
        function setTemperature(this, dValC)
            
            % multiply the value by 10 and convert to 16-bit int
            u16Val = uint16(dValC * 10);
            
            % convert to hex (force 4 characters)
            cxVal = dec2hex(u16Val);
            
            % reshape into a {2x2 char array}
            cxVal = reshape(cxVal, 2, 2);
            
            % crate 8x2 char array of 8 hex bytes (64-bit)
            cxId = '01';
            cxFcn = '06';
            cxAddr = ['00'; '00'];
            cxCrc = ['cc'; 'cc'];
            cCmd = [cxId; cxFcn; cxAddr; cxVal; cxCrc];
            
            this.write(hex2dec(cCmd));
            
        end
        
        % Returns the current temperature in C
        function d = getCurrentTemperature(this)
            
            % crate 8x2 char array of 8 hex bytes (64-bit)

            cxId = '01';
            cxFcn = '03';
            cxAddr = ['10'; '00'];
            cxCount = ['00'; '01'];
            cxCrc = ['cc'; 'cc'];
            
            cCmd = [cxId; cxFcn; cxAddr; cxCount; cxCrc];
            
            this.write(hex2dec(cCmd));
            
            this.waitForBytesAvailable(8);
            
            % {uint8 mx1} fread returns {uint8 8x1} 8-byte response
            u8Response = fread(this.comm, this.comm.BytesAvailable);
            
            % Bytes 5 and 6 of the response contain the temperature data
            u8Data = u8Response(5:6);
            
            % Convert each 1-byte int to hex representation
            % (force two hex characters for each)
            cxData = dec2hex(u8Data,2);
            
            % combine into a single 2-byte hex value, e.g., x011F 
            cxData = reshape(cxData, 1, 4);
            
            % convert to decimal
            % and divide by 10 since hardware returns a 0.1C resolution value
            % multiplied by 10
            d = hex2dec(cxData) / 10;
        end
        
        
        
        
        
        % {uint8 1xm} list of bytes in decimal including terminator
        function write(this, u8Data)
            switch this.cConnection
                case {this.cCONNECTION_SERIAL, this.cCONNECTION_TCPIP}
                     fwrite(this.comm, u8Data);
                case this.cCONNECTION_TCPCLIENT
                     write(this.comm, u8Data);
            end
        end
        
        
    end
    
    
    methods (Access = protected)
        
        
        function msg(~, cMsg)
            fprintf('ATEC302 %s\n', cMsg);
        end
        
        function l = hasProp(this, c)
            
            l = false;
            if ~isempty(findprop(this, c))
                l = true;
            end
            
        end
        
        % Blocks execution until the serial has provided BytesAvailable
        % @param {int 1x1} the number of bytes to wait for
        function waitForBytesAvailable(this, dBytesExpected)
            
            if this.lShowWaitingForBytes
                cMsg = sprintf(...
                    'waitForBytesAvailable(%1.0f)', ...
                    dBytesExpected ...
                );
                this.msg(cMsg);
            end
                        
            while this.comm.BytesAvailable < dBytesExpected
                
                if this.lShowWaitingForBytes
                    cMsg = sprintf(...
                        'Waiting ... %1.0f of %1.0f expected bytes are currently available', ...
                        this.comm.BytesAvailable, ...
                        dBytesExpected ...
                    );
                    this.msg(cMsg);
                end
                
                if (toc > this.dTimeout)
                    cMsg = sprintf(...
                        'Error.  Serial took too long (> %1.1f sec) to reach expected %1.0f BytesAvailable %1.0f', ...
                        this.dTimeout, ...
                        dBytesExpected ...
                    );
                    error(cMsg);
                end
            end
            
        end
        
    end
    
    
    
    
end

