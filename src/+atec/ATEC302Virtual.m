classdef ATEC302Virtual <  atec.AbstractATEC302
    
 
    properties (Constant)
            
        
    end
    
    properties (SetAccess = private)
                        
        % {double 1x1} storage of the last successfully read value
        dSetValue = 10;
        % {double 1x1} storage of the last successfully read temp
        dTemperature = 15;
        
        % {char 1x4} storage of the last successfully read enabled state
        cxEnabledState = '0000' 
        
        lIsDisabled = false;
        lIsEnabledSPON = true;
    end
    
    
    methods
        
        function this = ATEC302Virtual(varargin)
                        
        end
        
        
        % Returns {logical} true if output is off
        function lReturn = getIsDisabled(this)
            lReturn = this.lIsDisabled;
        end 
        
        
        % Returns {logical} true if in single
        % point temp control (SPON)
        function lReturn = getIsEnabledSPON(this)
            lReturn = this.lIsEnabledSPON;
        end 
        
        % Sets ENAB to "off"
        function disable(this)
            this.lIsDisabled = true;
        end
        
        % Sets ENAB to single point temp control (SPON)
        function enableSPON(this)
            this.lIsEnabledSPON = true;
            
        end
        
        
        % Write a new setpoint to the hardware.  This is reverred to as the
        % Set Value (SV) in the manual, so this class follows that
        % nomenclature
        % @param {double 1x1} dValC - degrees C
        function setSetValue(this, dValC)
            this.dSetValue = dValC;
        end
        
        % Returns the setpoint in cegrees C
        % @param {double 1x1} dValC - degrees C
        function d = getSetValue(this)
            d = this.dSetValue;         
        end
        
        % Returns the current temperature in C
        function d = getTemperature(this)
            d = this.dTemperature;
        end
        
    end
    
    
    methods (Access = protected)
        
        
        
    end
    
    
    
    
end

