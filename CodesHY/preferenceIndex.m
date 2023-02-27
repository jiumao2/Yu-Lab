function out = preferenceIndex(preferredValue, nonpreferredValue)
    if any(preferredValue<0) || any(nonpreferredValue<0)
        error('Value should not be smaller than 0!');
    end
    out = (preferredValue-nonpreferredValue)./(preferredValue+nonpreferredValue);
end