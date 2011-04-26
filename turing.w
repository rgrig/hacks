@* Intro. This is an interpreter for TMs (Turing machines). Tape~$0$ is the
input tape; tape~$1$ is the output tape.

% TODO: characters 0-9 a-z
% TODO: metachars . (don't care, don't do anything), _ (blank), A-Z (vars)
% TODO: top-down pattern matching

Here is a TM that reverses its input.
%TODO: center
$$\catcode`\_=11\tt\halign{#\hfil&\quad#&\quad#&\quad#\hfil\cr
&01&0 1\cr % TODO say that this line is ignored
gotoEnd&_.&.<..&scan\cr
&..&.>..\cr
scan&_.&....&halt\cr
&X.&.<X>\cr}$$


% vim:tw=78:fo+=tc:
