classdef AbstractATEC302 < handle
    
 
    properties (Constant)
            
        
    end
    
    properties (SetAccess = private)
                        
         
    end
    
    
    methods
        
        
        % Returns {logical} true if output is off
        lReturn = getIsDisabled(this)
        lReturn = getIsEnabledSPON(this)
        disable(this)
        
        % Sets ENAB to single point temp control (SPON)
        enableSPON(this)
        
        % Write a new setpoint to the hardware.  This is reverred to as the
        % Set Value (SV) in the manual, so this class follows that
        % nomenclature
        % @param {double 1x1} dValC - degrees C
        setSetValue(this, dValC)
        
        % Returns the setpoint in cegrees C
        % @param {double 1x1} dValC - degrees C
        d = getSetValue(this)
         
        % Returns the current temperature in C
        d = getTemperature(this)
          
        
    end
    

    
end

