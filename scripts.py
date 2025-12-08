chars = "-, ., _, ~, !, $, &, ', (, ), *, +, ,, ;, =, :, @, %"
print(",".join([f"'{char[0]}'" for char in chars.split()]))