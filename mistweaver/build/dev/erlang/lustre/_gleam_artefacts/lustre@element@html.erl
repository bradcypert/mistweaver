-module(lustre@element@html).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src/lustre/element/html.gleam").
-export([html/2, text/1, base/1, head/2, link/1, meta/1, style/2, title/2, body/2, address/2, article/2, aside/2, footer/2, header/2, h1/2, h2/2, h3/2, h4/2, h5/2, h6/2, hgroup/2, main/2, nav/2, section/2, search/2, blockquote/2, dd/2, 'div'/2, dl/2, dt/2, figcaption/2, figure/2, hr/1, li/2, menu/2, ol/2, p/2, pre/2, ul/2, a/2, abbr/2, b/2, bdi/2, bdo/2, br/1, cite/2, code/2, data/2, dfn/2, em/2, i/2, kbd/2, mark/2, q/2, rp/2, rt/2, ruby/2, s/2, samp/2, small/2, span/2, strong/2, sub/2, sup/2, time/2, u/2, var/2, wbr/1, area/1, audio/2, img/1, map/2, track/1, video/2, embed/1, iframe/1, object/1, picture/2, portal/1, source/1, math/2, svg/2, canvas/1, noscript/2, script/2, del/2, ins/2, caption/2, col/1, colgroup/2, table/2, tbody/2, td/2, tfoot/2, th/2, thead/2, tr/2, button/2, datalist/2, fieldset/2, form/2, input/1, label/2, legend/2, meter/2, optgroup/2, option/2, output/2, progress/2, select/2, textarea/2, details/2, dialog/2, summary/2, slot/2, template/2]).

-if(?OTP_RELEASE >= 27).
-define(MODULEDOC(Str), -moduledoc(Str)).
-define(DOC(Str), -doc(Str)).
-else.
-define(MODULEDOC(Str), -compile([])).
-define(DOC(Str), -compile([])).
-endif.

-file("src/lustre/element/html.gleam", 11).
?DOC("\n").
-spec html(
    list(lustre@vdom@vattr:attribute(CWS)),
    list(lustre@vdom@vnode:element(CWS))
) -> lustre@vdom@vnode:element(CWS).
html(Attrs, Children) ->
    lustre@element:element(<<"html"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 18).
-spec text(binary()) -> lustre@vdom@vnode:element(any()).
text(Content) ->
    lustre@element:text(Content).

-file("src/lustre/element/html.gleam", 25).
?DOC("\n").
-spec base(list(lustre@vdom@vattr:attribute(CXA))) -> lustre@vdom@vnode:element(CXA).
base(Attrs) ->
    lustre@element:element(<<"base"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 30).
?DOC("\n").
-spec head(
    list(lustre@vdom@vattr:attribute(CXE)),
    list(lustre@vdom@vnode:element(CXE))
) -> lustre@vdom@vnode:element(CXE).
head(Attrs, Children) ->
    lustre@element:element(<<"head"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 38).
?DOC("\n").
-spec link(list(lustre@vdom@vattr:attribute(CXK))) -> lustre@vdom@vnode:element(CXK).
link(Attrs) ->
    lustre@element:element(<<"link"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 43).
?DOC("\n").
-spec meta(list(lustre@vdom@vattr:attribute(CXO))) -> lustre@vdom@vnode:element(CXO).
meta(Attrs) ->
    lustre@element:element(<<"meta"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 48).
?DOC("\n").
-spec style(list(lustre@vdom@vattr:attribute(CXS)), binary()) -> lustre@vdom@vnode:element(CXS).
style(Attrs, Css) ->
    lustre@element:unsafe_raw_html(<<""/utf8>>, <<"style"/utf8>>, Attrs, Css).

-file("src/lustre/element/html.gleam", 53).
?DOC("\n").
-spec title(list(lustre@vdom@vattr:attribute(CXW)), binary()) -> lustre@vdom@vnode:element(CXW).
title(Attrs, Content) ->
    lustre@element:element(<<"title"/utf8>>, Attrs, [text(Content)]).

-file("src/lustre/element/html.gleam", 63).
?DOC("\n").
-spec body(
    list(lustre@vdom@vattr:attribute(CYA)),
    list(lustre@vdom@vnode:element(CYA))
) -> lustre@vdom@vnode:element(CYA).
body(Attrs, Children) ->
    lustre@element:element(<<"body"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 73).
?DOC("\n").
-spec address(
    list(lustre@vdom@vattr:attribute(CYG)),
    list(lustre@vdom@vnode:element(CYG))
) -> lustre@vdom@vnode:element(CYG).
address(Attrs, Children) ->
    lustre@element:element(<<"address"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 81).
?DOC("\n").
-spec article(
    list(lustre@vdom@vattr:attribute(CYM)),
    list(lustre@vdom@vnode:element(CYM))
) -> lustre@vdom@vnode:element(CYM).
article(Attrs, Children) ->
    lustre@element:element(<<"article"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 89).
?DOC("\n").
-spec aside(
    list(lustre@vdom@vattr:attribute(CYS)),
    list(lustre@vdom@vnode:element(CYS))
) -> lustre@vdom@vnode:element(CYS).
aside(Attrs, Children) ->
    lustre@element:element(<<"aside"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 97).
?DOC("\n").
-spec footer(
    list(lustre@vdom@vattr:attribute(CYY)),
    list(lustre@vdom@vnode:element(CYY))
) -> lustre@vdom@vnode:element(CYY).
footer(Attrs, Children) ->
    lustre@element:element(<<"footer"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 105).
?DOC("\n").
-spec header(
    list(lustre@vdom@vattr:attribute(CZE)),
    list(lustre@vdom@vnode:element(CZE))
) -> lustre@vdom@vnode:element(CZE).
header(Attrs, Children) ->
    lustre@element:element(<<"header"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 113).
?DOC("\n").
-spec h1(
    list(lustre@vdom@vattr:attribute(CZK)),
    list(lustre@vdom@vnode:element(CZK))
) -> lustre@vdom@vnode:element(CZK).
h1(Attrs, Children) ->
    lustre@element:element(<<"h1"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 121).
?DOC("\n").
-spec h2(
    list(lustre@vdom@vattr:attribute(CZQ)),
    list(lustre@vdom@vnode:element(CZQ))
) -> lustre@vdom@vnode:element(CZQ).
h2(Attrs, Children) ->
    lustre@element:element(<<"h2"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 129).
?DOC("\n").
-spec h3(
    list(lustre@vdom@vattr:attribute(CZW)),
    list(lustre@vdom@vnode:element(CZW))
) -> lustre@vdom@vnode:element(CZW).
h3(Attrs, Children) ->
    lustre@element:element(<<"h3"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 137).
?DOC("\n").
-spec h4(
    list(lustre@vdom@vattr:attribute(DAC)),
    list(lustre@vdom@vnode:element(DAC))
) -> lustre@vdom@vnode:element(DAC).
h4(Attrs, Children) ->
    lustre@element:element(<<"h4"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 145).
?DOC("\n").
-spec h5(
    list(lustre@vdom@vattr:attribute(DAI)),
    list(lustre@vdom@vnode:element(DAI))
) -> lustre@vdom@vnode:element(DAI).
h5(Attrs, Children) ->
    lustre@element:element(<<"h5"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 153).
?DOC("\n").
-spec h6(
    list(lustre@vdom@vattr:attribute(DAO)),
    list(lustre@vdom@vnode:element(DAO))
) -> lustre@vdom@vnode:element(DAO).
h6(Attrs, Children) ->
    lustre@element:element(<<"h6"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 161).
?DOC("\n").
-spec hgroup(
    list(lustre@vdom@vattr:attribute(DAU)),
    list(lustre@vdom@vnode:element(DAU))
) -> lustre@vdom@vnode:element(DAU).
hgroup(Attrs, Children) ->
    lustre@element:element(<<"hgroup"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 169).
?DOC("\n").
-spec main(
    list(lustre@vdom@vattr:attribute(DBA)),
    list(lustre@vdom@vnode:element(DBA))
) -> lustre@vdom@vnode:element(DBA).
main(Attrs, Children) ->
    lustre@element:element(<<"main"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 177).
?DOC("\n").
-spec nav(
    list(lustre@vdom@vattr:attribute(DBG)),
    list(lustre@vdom@vnode:element(DBG))
) -> lustre@vdom@vnode:element(DBG).
nav(Attrs, Children) ->
    lustre@element:element(<<"nav"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 185).
?DOC("\n").
-spec section(
    list(lustre@vdom@vattr:attribute(DBM)),
    list(lustre@vdom@vnode:element(DBM))
) -> lustre@vdom@vnode:element(DBM).
section(Attrs, Children) ->
    lustre@element:element(<<"section"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 193).
?DOC("\n").
-spec search(
    list(lustre@vdom@vattr:attribute(DBS)),
    list(lustre@vdom@vnode:element(DBS))
) -> lustre@vdom@vnode:element(DBS).
search(Attrs, Children) ->
    lustre@element:element(<<"search"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 203).
?DOC("\n").
-spec blockquote(
    list(lustre@vdom@vattr:attribute(DBY)),
    list(lustre@vdom@vnode:element(DBY))
) -> lustre@vdom@vnode:element(DBY).
blockquote(Attrs, Children) ->
    lustre@element:element(<<"blockquote"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 211).
?DOC("\n").
-spec dd(
    list(lustre@vdom@vattr:attribute(DCE)),
    list(lustre@vdom@vnode:element(DCE))
) -> lustre@vdom@vnode:element(DCE).
dd(Attrs, Children) ->
    lustre@element:element(<<"dd"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 219).
?DOC("\n").
-spec 'div'(
    list(lustre@vdom@vattr:attribute(DCK)),
    list(lustre@vdom@vnode:element(DCK))
) -> lustre@vdom@vnode:element(DCK).
'div'(Attrs, Children) ->
    lustre@element:element(<<"div"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 227).
?DOC("\n").
-spec dl(
    list(lustre@vdom@vattr:attribute(DCQ)),
    list(lustre@vdom@vnode:element(DCQ))
) -> lustre@vdom@vnode:element(DCQ).
dl(Attrs, Children) ->
    lustre@element:element(<<"dl"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 235).
?DOC("\n").
-spec dt(
    list(lustre@vdom@vattr:attribute(DCW)),
    list(lustre@vdom@vnode:element(DCW))
) -> lustre@vdom@vnode:element(DCW).
dt(Attrs, Children) ->
    lustre@element:element(<<"dt"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 243).
?DOC("\n").
-spec figcaption(
    list(lustre@vdom@vattr:attribute(DDC)),
    list(lustre@vdom@vnode:element(DDC))
) -> lustre@vdom@vnode:element(DDC).
figcaption(Attrs, Children) ->
    lustre@element:element(<<"figcaption"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 251).
?DOC("\n").
-spec figure(
    list(lustre@vdom@vattr:attribute(DDI)),
    list(lustre@vdom@vnode:element(DDI))
) -> lustre@vdom@vnode:element(DDI).
figure(Attrs, Children) ->
    lustre@element:element(<<"figure"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 259).
?DOC("\n").
-spec hr(list(lustre@vdom@vattr:attribute(DDO))) -> lustre@vdom@vnode:element(DDO).
hr(Attrs) ->
    lustre@element:element(<<"hr"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 264).
?DOC("\n").
-spec li(
    list(lustre@vdom@vattr:attribute(DDS)),
    list(lustre@vdom@vnode:element(DDS))
) -> lustre@vdom@vnode:element(DDS).
li(Attrs, Children) ->
    lustre@element:element(<<"li"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 272).
?DOC("\n").
-spec menu(
    list(lustre@vdom@vattr:attribute(DDY)),
    list(lustre@vdom@vnode:element(DDY))
) -> lustre@vdom@vnode:element(DDY).
menu(Attrs, Children) ->
    lustre@element:element(<<"menu"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 280).
?DOC("\n").
-spec ol(
    list(lustre@vdom@vattr:attribute(DEE)),
    list(lustre@vdom@vnode:element(DEE))
) -> lustre@vdom@vnode:element(DEE).
ol(Attrs, Children) ->
    lustre@element:element(<<"ol"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 288).
?DOC("\n").
-spec p(
    list(lustre@vdom@vattr:attribute(DEK)),
    list(lustre@vdom@vnode:element(DEK))
) -> lustre@vdom@vnode:element(DEK).
p(Attrs, Children) ->
    lustre@element:element(<<"p"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 296).
?DOC("\n").
-spec pre(
    list(lustre@vdom@vattr:attribute(DEQ)),
    list(lustre@vdom@vnode:element(DEQ))
) -> lustre@vdom@vnode:element(DEQ).
pre(Attrs, Children) ->
    lustre@element:element(<<"pre"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 304).
?DOC("\n").
-spec ul(
    list(lustre@vdom@vattr:attribute(DEW)),
    list(lustre@vdom@vnode:element(DEW))
) -> lustre@vdom@vnode:element(DEW).
ul(Attrs, Children) ->
    lustre@element:element(<<"ul"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 314).
?DOC("\n").
-spec a(
    list(lustre@vdom@vattr:attribute(DFC)),
    list(lustre@vdom@vnode:element(DFC))
) -> lustre@vdom@vnode:element(DFC).
a(Attrs, Children) ->
    lustre@element:element(<<"a"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 322).
?DOC("\n").
-spec abbr(
    list(lustre@vdom@vattr:attribute(DFI)),
    list(lustre@vdom@vnode:element(DFI))
) -> lustre@vdom@vnode:element(DFI).
abbr(Attrs, Children) ->
    lustre@element:element(<<"abbr"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 330).
?DOC("\n").
-spec b(
    list(lustre@vdom@vattr:attribute(DFO)),
    list(lustre@vdom@vnode:element(DFO))
) -> lustre@vdom@vnode:element(DFO).
b(Attrs, Children) ->
    lustre@element:element(<<"b"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 338).
?DOC("\n").
-spec bdi(
    list(lustre@vdom@vattr:attribute(DFU)),
    list(lustre@vdom@vnode:element(DFU))
) -> lustre@vdom@vnode:element(DFU).
bdi(Attrs, Children) ->
    lustre@element:element(<<"bdi"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 346).
?DOC("\n").
-spec bdo(
    list(lustre@vdom@vattr:attribute(DGA)),
    list(lustre@vdom@vnode:element(DGA))
) -> lustre@vdom@vnode:element(DGA).
bdo(Attrs, Children) ->
    lustre@element:element(<<"bdo"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 354).
?DOC("\n").
-spec br(list(lustre@vdom@vattr:attribute(DGG))) -> lustre@vdom@vnode:element(DGG).
br(Attrs) ->
    lustre@element:element(<<"br"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 359).
?DOC("\n").
-spec cite(
    list(lustre@vdom@vattr:attribute(DGK)),
    list(lustre@vdom@vnode:element(DGK))
) -> lustre@vdom@vnode:element(DGK).
cite(Attrs, Children) ->
    lustre@element:element(<<"cite"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 367).
?DOC("\n").
-spec code(
    list(lustre@vdom@vattr:attribute(DGQ)),
    list(lustre@vdom@vnode:element(DGQ))
) -> lustre@vdom@vnode:element(DGQ).
code(Attrs, Children) ->
    lustre@element:element(<<"code"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 375).
?DOC("\n").
-spec data(
    list(lustre@vdom@vattr:attribute(DGW)),
    list(lustre@vdom@vnode:element(DGW))
) -> lustre@vdom@vnode:element(DGW).
data(Attrs, Children) ->
    lustre@element:element(<<"data"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 383).
?DOC("\n").
-spec dfn(
    list(lustre@vdom@vattr:attribute(DHC)),
    list(lustre@vdom@vnode:element(DHC))
) -> lustre@vdom@vnode:element(DHC).
dfn(Attrs, Children) ->
    lustre@element:element(<<"dfn"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 391).
?DOC("\n").
-spec em(
    list(lustre@vdom@vattr:attribute(DHI)),
    list(lustre@vdom@vnode:element(DHI))
) -> lustre@vdom@vnode:element(DHI).
em(Attrs, Children) ->
    lustre@element:element(<<"em"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 399).
?DOC("\n").
-spec i(
    list(lustre@vdom@vattr:attribute(DHO)),
    list(lustre@vdom@vnode:element(DHO))
) -> lustre@vdom@vnode:element(DHO).
i(Attrs, Children) ->
    lustre@element:element(<<"i"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 407).
?DOC("\n").
-spec kbd(
    list(lustre@vdom@vattr:attribute(DHU)),
    list(lustre@vdom@vnode:element(DHU))
) -> lustre@vdom@vnode:element(DHU).
kbd(Attrs, Children) ->
    lustre@element:element(<<"kbd"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 415).
?DOC("\n").
-spec mark(
    list(lustre@vdom@vattr:attribute(DIA)),
    list(lustre@vdom@vnode:element(DIA))
) -> lustre@vdom@vnode:element(DIA).
mark(Attrs, Children) ->
    lustre@element:element(<<"mark"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 423).
?DOC("\n").
-spec q(
    list(lustre@vdom@vattr:attribute(DIG)),
    list(lustre@vdom@vnode:element(DIG))
) -> lustre@vdom@vnode:element(DIG).
q(Attrs, Children) ->
    lustre@element:element(<<"q"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 431).
?DOC("\n").
-spec rp(
    list(lustre@vdom@vattr:attribute(DIM)),
    list(lustre@vdom@vnode:element(DIM))
) -> lustre@vdom@vnode:element(DIM).
rp(Attrs, Children) ->
    lustre@element:element(<<"rp"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 439).
?DOC("\n").
-spec rt(
    list(lustre@vdom@vattr:attribute(DIS)),
    list(lustre@vdom@vnode:element(DIS))
) -> lustre@vdom@vnode:element(DIS).
rt(Attrs, Children) ->
    lustre@element:element(<<"rt"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 447).
?DOC("\n").
-spec ruby(
    list(lustre@vdom@vattr:attribute(DIY)),
    list(lustre@vdom@vnode:element(DIY))
) -> lustre@vdom@vnode:element(DIY).
ruby(Attrs, Children) ->
    lustre@element:element(<<"ruby"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 455).
?DOC("\n").
-spec s(
    list(lustre@vdom@vattr:attribute(DJE)),
    list(lustre@vdom@vnode:element(DJE))
) -> lustre@vdom@vnode:element(DJE).
s(Attrs, Children) ->
    lustre@element:element(<<"s"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 463).
?DOC("\n").
-spec samp(
    list(lustre@vdom@vattr:attribute(DJK)),
    list(lustre@vdom@vnode:element(DJK))
) -> lustre@vdom@vnode:element(DJK).
samp(Attrs, Children) ->
    lustre@element:element(<<"samp"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 471).
?DOC("\n").
-spec small(
    list(lustre@vdom@vattr:attribute(DJQ)),
    list(lustre@vdom@vnode:element(DJQ))
) -> lustre@vdom@vnode:element(DJQ).
small(Attrs, Children) ->
    lustre@element:element(<<"small"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 479).
?DOC("\n").
-spec span(
    list(lustre@vdom@vattr:attribute(DJW)),
    list(lustre@vdom@vnode:element(DJW))
) -> lustre@vdom@vnode:element(DJW).
span(Attrs, Children) ->
    lustre@element:element(<<"span"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 487).
?DOC("\n").
-spec strong(
    list(lustre@vdom@vattr:attribute(DKC)),
    list(lustre@vdom@vnode:element(DKC))
) -> lustre@vdom@vnode:element(DKC).
strong(Attrs, Children) ->
    lustre@element:element(<<"strong"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 495).
?DOC("\n").
-spec sub(
    list(lustre@vdom@vattr:attribute(DKI)),
    list(lustre@vdom@vnode:element(DKI))
) -> lustre@vdom@vnode:element(DKI).
sub(Attrs, Children) ->
    lustre@element:element(<<"sub"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 503).
?DOC("\n").
-spec sup(
    list(lustre@vdom@vattr:attribute(DKO)),
    list(lustre@vdom@vnode:element(DKO))
) -> lustre@vdom@vnode:element(DKO).
sup(Attrs, Children) ->
    lustre@element:element(<<"sup"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 511).
?DOC("\n").
-spec time(
    list(lustre@vdom@vattr:attribute(DKU)),
    list(lustre@vdom@vnode:element(DKU))
) -> lustre@vdom@vnode:element(DKU).
time(Attrs, Children) ->
    lustre@element:element(<<"time"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 519).
?DOC("\n").
-spec u(
    list(lustre@vdom@vattr:attribute(DLA)),
    list(lustre@vdom@vnode:element(DLA))
) -> lustre@vdom@vnode:element(DLA).
u(Attrs, Children) ->
    lustre@element:element(<<"u"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 527).
?DOC("\n").
-spec var(
    list(lustre@vdom@vattr:attribute(DLG)),
    list(lustre@vdom@vnode:element(DLG))
) -> lustre@vdom@vnode:element(DLG).
var(Attrs, Children) ->
    lustre@element:element(<<"var"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 535).
?DOC("\n").
-spec wbr(list(lustre@vdom@vattr:attribute(DLM))) -> lustre@vdom@vnode:element(DLM).
wbr(Attrs) ->
    lustre@element:element(<<"wbr"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 542).
?DOC("\n").
-spec area(list(lustre@vdom@vattr:attribute(DLQ))) -> lustre@vdom@vnode:element(DLQ).
area(Attrs) ->
    lustre@element:element(<<"area"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 547).
?DOC("\n").
-spec audio(
    list(lustre@vdom@vattr:attribute(DLU)),
    list(lustre@vdom@vnode:element(DLU))
) -> lustre@vdom@vnode:element(DLU).
audio(Attrs, Children) ->
    lustre@element:element(<<"audio"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 555).
?DOC("\n").
-spec img(list(lustre@vdom@vattr:attribute(DMA))) -> lustre@vdom@vnode:element(DMA).
img(Attrs) ->
    lustre@element:element(<<"img"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 561).
?DOC(" Used with <area> elements to define an image map (a clickable link area).\n").
-spec map(
    list(lustre@vdom@vattr:attribute(DME)),
    list(lustre@vdom@vnode:element(DME))
) -> lustre@vdom@vnode:element(DME).
map(Attrs, Children) ->
    lustre@element:element(<<"map"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 569).
?DOC("\n").
-spec track(list(lustre@vdom@vattr:attribute(DMK))) -> lustre@vdom@vnode:element(DMK).
track(Attrs) ->
    lustre@element:element(<<"track"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 574).
?DOC("\n").
-spec video(
    list(lustre@vdom@vattr:attribute(DMO)),
    list(lustre@vdom@vnode:element(DMO))
) -> lustre@vdom@vnode:element(DMO).
video(Attrs, Children) ->
    lustre@element:element(<<"video"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 584).
?DOC("\n").
-spec embed(list(lustre@vdom@vattr:attribute(DMU))) -> lustre@vdom@vnode:element(DMU).
embed(Attrs) ->
    lustre@element:element(<<"embed"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 589).
?DOC("\n").
-spec iframe(list(lustre@vdom@vattr:attribute(DMY))) -> lustre@vdom@vnode:element(DMY).
iframe(Attrs) ->
    lustre@element:element(<<"iframe"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 594).
?DOC("\n").
-spec object(list(lustre@vdom@vattr:attribute(DNC))) -> lustre@vdom@vnode:element(DNC).
object(Attrs) ->
    lustre@element:element(<<"object"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 599).
?DOC("\n").
-spec picture(
    list(lustre@vdom@vattr:attribute(DNG)),
    list(lustre@vdom@vnode:element(DNG))
) -> lustre@vdom@vnode:element(DNG).
picture(Attrs, Children) ->
    lustre@element:element(<<"picture"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 607).
?DOC("\n").
-spec portal(list(lustre@vdom@vattr:attribute(DNM))) -> lustre@vdom@vnode:element(DNM).
portal(Attrs) ->
    lustre@element:element(<<"portal"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 612).
?DOC("\n").
-spec source(list(lustre@vdom@vattr:attribute(DNQ))) -> lustre@vdom@vnode:element(DNQ).
source(Attrs) ->
    lustre@element:element(<<"source"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 619).
?DOC("\n").
-spec math(
    list(lustre@vdom@vattr:attribute(DNU)),
    list(lustre@vdom@vnode:element(DNU))
) -> lustre@vdom@vnode:element(DNU).
math(Attrs, Children) ->
    lustre@element:namespaced(
        <<"http://www.w3.org/1998/Math/MathML"/utf8>>,
        <<"math"/utf8>>,
        Attrs,
        Children
    ).

-file("src/lustre/element/html.gleam", 627).
?DOC("\n").
-spec svg(
    list(lustre@vdom@vattr:attribute(DOA)),
    list(lustre@vdom@vnode:element(DOA))
) -> lustre@vdom@vnode:element(DOA).
svg(Attrs, Children) ->
    lustre@element:namespaced(
        <<"http://www.w3.org/2000/svg"/utf8>>,
        <<"svg"/utf8>>,
        Attrs,
        Children
    ).

-file("src/lustre/element/html.gleam", 637).
?DOC("\n").
-spec canvas(list(lustre@vdom@vattr:attribute(DOG))) -> lustre@vdom@vnode:element(DOG).
canvas(Attrs) ->
    lustre@element:element(<<"canvas"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 642).
?DOC("\n").
-spec noscript(
    list(lustre@vdom@vattr:attribute(DOK)),
    list(lustre@vdom@vnode:element(DOK))
) -> lustre@vdom@vnode:element(DOK).
noscript(Attrs, Children) ->
    lustre@element:element(<<"noscript"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 650).
?DOC("\n").
-spec script(list(lustre@vdom@vattr:attribute(DOQ)), binary()) -> lustre@vdom@vnode:element(DOQ).
script(Attrs, Js) ->
    lustre@element:unsafe_raw_html(<<""/utf8>>, <<"script"/utf8>>, Attrs, Js).

-file("src/lustre/element/html.gleam", 657).
?DOC("\n").
-spec del(
    list(lustre@vdom@vattr:attribute(DOU)),
    list(lustre@vdom@vnode:element(DOU))
) -> lustre@vdom@vnode:element(DOU).
del(Attrs, Children) ->
    lustre@element:element(<<"del"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 665).
?DOC("\n").
-spec ins(
    list(lustre@vdom@vattr:attribute(DPA)),
    list(lustre@vdom@vnode:element(DPA))
) -> lustre@vdom@vnode:element(DPA).
ins(Attrs, Children) ->
    lustre@element:element(<<"ins"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 675).
?DOC("\n").
-spec caption(
    list(lustre@vdom@vattr:attribute(DPG)),
    list(lustre@vdom@vnode:element(DPG))
) -> lustre@vdom@vnode:element(DPG).
caption(Attrs, Children) ->
    lustre@element:element(<<"caption"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 683).
?DOC("\n").
-spec col(list(lustre@vdom@vattr:attribute(DPM))) -> lustre@vdom@vnode:element(DPM).
col(Attrs) ->
    lustre@element:element(<<"col"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 688).
?DOC("\n").
-spec colgroup(
    list(lustre@vdom@vattr:attribute(DPQ)),
    list(lustre@vdom@vnode:element(DPQ))
) -> lustre@vdom@vnode:element(DPQ).
colgroup(Attrs, Children) ->
    lustre@element:element(<<"colgroup"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 696).
?DOC("\n").
-spec table(
    list(lustre@vdom@vattr:attribute(DPW)),
    list(lustre@vdom@vnode:element(DPW))
) -> lustre@vdom@vnode:element(DPW).
table(Attrs, Children) ->
    lustre@element:element(<<"table"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 704).
?DOC("\n").
-spec tbody(
    list(lustre@vdom@vattr:attribute(DQC)),
    list(lustre@vdom@vnode:element(DQC))
) -> lustre@vdom@vnode:element(DQC).
tbody(Attrs, Children) ->
    lustre@element:element(<<"tbody"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 712).
?DOC("\n").
-spec td(
    list(lustre@vdom@vattr:attribute(DQI)),
    list(lustre@vdom@vnode:element(DQI))
) -> lustre@vdom@vnode:element(DQI).
td(Attrs, Children) ->
    lustre@element:element(<<"td"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 720).
?DOC("\n").
-spec tfoot(
    list(lustre@vdom@vattr:attribute(DQO)),
    list(lustre@vdom@vnode:element(DQO))
) -> lustre@vdom@vnode:element(DQO).
tfoot(Attrs, Children) ->
    lustre@element:element(<<"tfoot"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 728).
?DOC("\n").
-spec th(
    list(lustre@vdom@vattr:attribute(DQU)),
    list(lustre@vdom@vnode:element(DQU))
) -> lustre@vdom@vnode:element(DQU).
th(Attrs, Children) ->
    lustre@element:element(<<"th"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 736).
?DOC("\n").
-spec thead(
    list(lustre@vdom@vattr:attribute(DRA)),
    list(lustre@vdom@vnode:element(DRA))
) -> lustre@vdom@vnode:element(DRA).
thead(Attrs, Children) ->
    lustre@element:element(<<"thead"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 744).
?DOC("\n").
-spec tr(
    list(lustre@vdom@vattr:attribute(DRG)),
    list(lustre@vdom@vnode:element(DRG))
) -> lustre@vdom@vnode:element(DRG).
tr(Attrs, Children) ->
    lustre@element:element(<<"tr"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 754).
?DOC("\n").
-spec button(
    list(lustre@vdom@vattr:attribute(DRM)),
    list(lustre@vdom@vnode:element(DRM))
) -> lustre@vdom@vnode:element(DRM).
button(Attrs, Children) ->
    lustre@element:element(<<"button"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 762).
?DOC("\n").
-spec datalist(
    list(lustre@vdom@vattr:attribute(DRS)),
    list(lustre@vdom@vnode:element(DRS))
) -> lustre@vdom@vnode:element(DRS).
datalist(Attrs, Children) ->
    lustre@element:element(<<"datalist"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 770).
?DOC("\n").
-spec fieldset(
    list(lustre@vdom@vattr:attribute(DRY)),
    list(lustre@vdom@vnode:element(DRY))
) -> lustre@vdom@vnode:element(DRY).
fieldset(Attrs, Children) ->
    lustre@element:element(<<"fieldset"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 778).
?DOC("\n").
-spec form(
    list(lustre@vdom@vattr:attribute(DSE)),
    list(lustre@vdom@vnode:element(DSE))
) -> lustre@vdom@vnode:element(DSE).
form(Attrs, Children) ->
    lustre@element:element(<<"form"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 786).
?DOC("\n").
-spec input(list(lustre@vdom@vattr:attribute(DSK))) -> lustre@vdom@vnode:element(DSK).
input(Attrs) ->
    lustre@element:element(<<"input"/utf8>>, Attrs, []).

-file("src/lustre/element/html.gleam", 791).
?DOC("\n").
-spec label(
    list(lustre@vdom@vattr:attribute(DSO)),
    list(lustre@vdom@vnode:element(DSO))
) -> lustre@vdom@vnode:element(DSO).
label(Attrs, Children) ->
    lustre@element:element(<<"label"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 799).
?DOC("\n").
-spec legend(
    list(lustre@vdom@vattr:attribute(DSU)),
    list(lustre@vdom@vnode:element(DSU))
) -> lustre@vdom@vnode:element(DSU).
legend(Attrs, Children) ->
    lustre@element:element(<<"legend"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 807).
?DOC("\n").
-spec meter(
    list(lustre@vdom@vattr:attribute(DTA)),
    list(lustre@vdom@vnode:element(DTA))
) -> lustre@vdom@vnode:element(DTA).
meter(Attrs, Children) ->
    lustre@element:element(<<"meter"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 815).
?DOC("\n").
-spec optgroup(
    list(lustre@vdom@vattr:attribute(DTG)),
    list(lustre@vdom@vnode:element(DTG))
) -> lustre@vdom@vnode:element(DTG).
optgroup(Attrs, Children) ->
    lustre@element:element(<<"optgroup"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 823).
?DOC("\n").
-spec option(list(lustre@vdom@vattr:attribute(DTM)), binary()) -> lustre@vdom@vnode:element(DTM).
option(Attrs, Label) ->
    lustre@element:element(
        <<"option"/utf8>>,
        Attrs,
        [lustre@element:text(Label)]
    ).

-file("src/lustre/element/html.gleam", 831).
?DOC("\n").
-spec output(
    list(lustre@vdom@vattr:attribute(DTQ)),
    list(lustre@vdom@vnode:element(DTQ))
) -> lustre@vdom@vnode:element(DTQ).
output(Attrs, Children) ->
    lustre@element:element(<<"output"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 839).
?DOC("\n").
-spec progress(
    list(lustre@vdom@vattr:attribute(DTW)),
    list(lustre@vdom@vnode:element(DTW))
) -> lustre@vdom@vnode:element(DTW).
progress(Attrs, Children) ->
    lustre@element:element(<<"progress"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 847).
?DOC("\n").
-spec select(
    list(lustre@vdom@vattr:attribute(DUC)),
    list(lustre@vdom@vnode:element(DUC))
) -> lustre@vdom@vnode:element(DUC).
select(Attrs, Children) ->
    lustre@element:element(<<"select"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 855).
?DOC("\n").
-spec textarea(list(lustre@vdom@vattr:attribute(DUI)), binary()) -> lustre@vdom@vnode:element(DUI).
textarea(Attrs, Content) ->
    lustre@element:element(
        <<"textarea"/utf8>>,
        [lustre@attribute:property(<<"value"/utf8>>, gleam@json:string(Content)) |
            Attrs],
        [lustre@element:text(Content)]
    ).

-file("src/lustre/element/html.gleam", 869).
?DOC("\n").
-spec details(
    list(lustre@vdom@vattr:attribute(DUM)),
    list(lustre@vdom@vnode:element(DUM))
) -> lustre@vdom@vnode:element(DUM).
details(Attrs, Children) ->
    lustre@element:element(<<"details"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 877).
?DOC("\n").
-spec dialog(
    list(lustre@vdom@vattr:attribute(DUS)),
    list(lustre@vdom@vnode:element(DUS))
) -> lustre@vdom@vnode:element(DUS).
dialog(Attrs, Children) ->
    lustre@element:element(<<"dialog"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 885).
?DOC("\n").
-spec summary(
    list(lustre@vdom@vattr:attribute(DUY)),
    list(lustre@vdom@vnode:element(DUY))
) -> lustre@vdom@vnode:element(DUY).
summary(Attrs, Children) ->
    lustre@element:element(<<"summary"/utf8>>, Attrs, Children).

-file("src/lustre/element/html.gleam", 895).
?DOC("\n").
-spec slot(
    list(lustre@vdom@vattr:attribute(DVE)),
    list(lustre@vdom@vnode:element(DVE))
) -> lustre@vdom@vnode:element(DVE).
slot(Attrs, Fallback) ->
    lustre@element:element(<<"slot"/utf8>>, Attrs, Fallback).

-file("src/lustre/element/html.gleam", 903).
?DOC("\n").
-spec template(
    list(lustre@vdom@vattr:attribute(DVK)),
    list(lustre@vdom@vnode:element(DVK))
) -> lustre@vdom@vnode:element(DVK).
template(Attrs, Children) ->
    lustre@element:element(<<"template"/utf8>>, Attrs, Children).
