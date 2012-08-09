package com.longtailvideo.adaptive.muxing {


    import com.longtailvideo.adaptive.muxing.*;
    import com.longtailvideo.adaptive.utils.*;
    import flash.utils.ByteArray;


    /** Representation of a Packetized Elementary Stream. **/
    public class PES {


        /** Timescale of pts/dts is 90khz. **/
        public static var TIMESCALE:Number = 90;


        /** Is it AAC audio or AVC video. **/
        public var audio:Boolean;
        /** The PES data (including headers). **/
        public var data:ByteArray;
        /** Start of the payload. **/
        public var payload:Number;
        /** Timestamp from the PTS header. **/
        public var pts:Number;
        /** Timestamp from the DTS header. **/
        public var dts:Number;


        /** Save the first chunk of PES data. **/
        public function PES(dat:ByteArray,aud:Boolean) {
            data = dat;
            audio = aud;
        };


        /** Append PES data from additional TS packets. **/
        public function append(dat:ByteArray):void {
            data.writeBytes(dat,0,0);
        };


        /** When all data is appended, parse the PES headers. **/
        public function parse():void {
            data.position = 0;
            // Start code prefix and packet ID.
            var prefix:Number = data.readUnsignedInt();
            if((audio && (prefix > 448 || prefix < 445)) ||
                (!audio && prefix != 480)) {
                throw new Error("PES start code not found or not AAC/AVC");
            }
            // Ignore packet length and marker bits.
            data.position += 3;
            // Check for PTS
            var flags:uint = (data.readUnsignedByte() & 192) >> 6;
            if(flags != 2 && flags != 3) {
                throw new Error("No PTS/DTS in this PES packet");
            }
            // Check PES header length
            var length:uint = data.readUnsignedByte();
            // Grab the timestamp from PTS data (spread out over 5 bytes):
            // XXXX---X -------- -------X -------- -------X
            var _pts:uint = ((data.readUnsignedByte() & 14) << 29) +
                ((data.readUnsignedShort() & 65535) << 14) +
                ((data.readUnsignedShort() & 65535) >> 1);
            length -= 5;
            var _dts:uint = _pts;
            if(flags == 3) {
                // Grab the DTS (like PTS)
                _dts = ((data.readUnsignedByte() & 14) << 29) +
                    ((data.readUnsignedShort() & 65535) << 14) +
                    ((data.readUnsignedShort() & 65535) >> 1);
                length -= 5;
            }
            pts = Math.round(_pts / PES.TIMESCALE);
            dts = Math.round(_dts / PES.TIMESCALE);
            // Skip other header data and parse payload.
            data.position += length;
            payload = data.position;
        };


    }


}