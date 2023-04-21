import Console.*;

import js.Node.*;
import js.node.*;

var Hyperswarm = require('hyperswarm');

/**
 * ...
 * @author Kyrasuum
 */
typedef T_peer = {senc: haxe.crypto.Aes, cenc: haxe.crypto.Aes, dh: Dynamic, timeout: haxe.Timer, topic: Buffer, sw: Dynamic, srv: Dynamic, cli: Dynamic};

@:expose
class P2P {
    public var timeout = 1000; //measured in milliseconds
    public var topic_str: String = 'default';

    var topic: Buffer;
    var sw: Dynamic;

    var peers: Map<String, T_peer> = [];
    var id = Crypto.randomBytes(32);

    //event handlers
    public var recv_msg = function(remote_id: Dynamic, data: Dynamic): String {return data;};
    public var new_conn = function(remote_id: Dynamic, topic: Dynamic) {};
    public var tim_conn = function(remote_id: Dynamic) {};
    public var lst_conn = function(remote_id: Dynamic) {};
    public var rst_conn = function(remote_id: Dynamic) {};
    public var err_msg = function(stage: String, remote_id: Dynamic, err: Dynamic) {};

    public function new() {
        //default event handlers
        recv_msg = function(remote_id: Dynamic, msg: String): String {
            println("");
            print("Message from ");
            print(remote_id);
            print(":");
            println(msg);

            return "";
        };
        new_conn = function(remote_id: Dynamic, topic: Dynamic) {
            println("");
            print("Connection from ");
            println(remote_id);
            print("Topic: ");
            println(topic);
        };
        tim_conn = function(remote_id: Dynamic) {
            println("");
            print("Connection Timed out for: ");
            println(remote_id);
        };
        lst_conn = function(remote_id: Dynamic) {
            println("");
            print("Lost connection to: ");
            println(remote_id);
        };
        rst_conn = function(remote_id: Dynamic) {
            println("");
            print("Restored connection to: ");
            println(remote_id);
        };
        err_msg = function(stage: String, remote_id: Dynamic, err: Dynamic) {
            println("");
            if (remote_id != null) {
                print("Error for: ");
                println(remote_id);
            }
            println(err);
        };
    }

    public function exit() {
        sw.destroy();
        for (peer in peers.keys()) {
            if (peers[peer].srv != null) {
                peers[peer].srv.destroy();
                peers[peer].senc = null;
            }
            if (peers[peer].cli != null) {
                peers[peer].cli.destroy();
                peers[peer].cenc = null;
            }
            peers[peer].sw.destroy();
        }
    }

    public function start() {
        //connection to search for peers
        topic = Crypto.createHash('sha256').update(topic_str).digest();
        sw = Hyperswarm();
        sw.join(topic, {lookup: true, announce: true});
        sw.on('error', function(err: Dynamic) {err_msg("room", null, err);});
        sw.on('connection', function(socket: Dynamic, info: Dynamic) {dhke_encrypt(0, socket, info, peer_discovery, function(err: Dynamic) {err_msg("discovery", null, err);});});
    }

    public function send_all(msg: String) {
        for (peer in peers.keys()) {
            var emsg = msg;
            if (peers[peer].srv != null) {
                if (peers[peer].senc != null) {
                    emsg = encrypt(msg, peers[peer].senc);
                }
                peers[peer].srv.write(emsg);
            } else if (peers[peer].cli != null) {
                if (peers[peer].cenc != null) {
                    emsg = encrypt(msg, peers[peer].cenc);
                }
                peers[peer].cli.write(emsg);
            }
        }
    }

    public function send(peer: Dynamic, msg: String) {
        if (peers.exists(peer)) {
            var emsg = msg;
            if (peers[peer].srv != null) {
                if (peers[peer].senc != null) {
                    emsg = encrypt(msg, peers[peer].senc);
                }
                peers[peer].srv.write(emsg);
            } else if (peers[peer].cli != null) {
                if (peers[peer].cenc != null) {
                    emsg = encrypt(msg, peers[peer].cenc);
                }
                peers[peer].cli.write(emsg);
            }
        }
    }

    private function dhke_encrypt(remote_id: Dynamic, socket: Dynamic, info: Dynamic, f_data: Dynamic, f_err: Dynamic) {
        socket.on('error', f_err);

        var enc = new haxe.crypto.Aes();
        var dh1 = Crypto.getDiffieHellman('modp14');
        var dh2 = Crypto.getDiffieHellman('modp14');
        dh1.generateKeys('hex');
        dh2.generateKeys('hex');

        var shrkey = "";
        var iv = "";

        if (remote_id != 0 && peers.exists(remote_id)) {
            if (info.client) {
                peers[remote_id].cenc = enc;
            } else {
                peers[remote_id].senc = enc;
            }
        }
        
        socket.write(dh1.getPublicKey('hex'));
        socket.on('data', function(jdata: Dynamic) {
            var data: String = jdata.toString();
            while (data.length > 0) {
                if (shrkey == "") {
                    shrkey = dh1.computeSecret(data.toString().substr(0, dh1.getPublicKey('hex').length), 'hex', 'hex');
                    data = data.substr(dh1.getPublicKey('hex').length);
                    socket.write(dh2.getPublicKey('hex'));
                    continue;
                }
                if (iv == "") {
                    iv = dh2.computeSecret(data.substr(0, dh2.getPublicKey('hex').length), 'hex', 'hex');
                    data = data.substr(dh2.getPublicKey('hex').length);
                    enc.init(haxe.io.Bytes.ofHex(shrkey), haxe.io.Bytes.ofHex(iv));
                    if (remote_id == 0) {
                        socket.write(encrypt(id.toString(), enc));
                    }
                    continue;
                }
                if (remote_id == 0) {
                    remote_id = decrypt(data, enc);
                    data = "";
                }
                data = f_data(remote_id, decrypt(data, enc));
            }
        });
    }

    private function peer_discovery(remote_id: Dynamic, data: Dynamic): String {
        if (peers.exists(remote_id)) return "";
        //construct deterministic private channel name
        var ids_conn = (id + remote_id).split("");
        ids_conn.sort(function(a: String, b: String) {
            if (a < b) return -1;
            if (a > b) return 1;
            return 0;
        });
        //create private channel
        var topic_conn = Crypto.createHash('sha256').update(ids_conn.join("")).digest();
        var sw: Dynamic = Hyperswarm();
        peers.set(remote_id, {senc: null, cenc: null, dh: null, timeout: null, topic: topic_conn, sw: sw, cli: null, srv: null});
        sw.join(topic_conn, {lookup: true, announce: true});
        sw.on('error', function(err: Dynamic) {err_msg("channel", null, err);});
        sw.on('disconnection', function(socket: Dynamic, info: Dynamic) {peer_disconnect(remote_id, socket, info);});
        sw.on('connection', function(socket: Dynamic, info: Dynamic) {peer_connect(remote_id, socket, info);});
        new_conn(remote_id, ids_conn.join(""));

        return "";
    }

    private function peer_connect(remote_id: Dynamic, socket: Dynamic, info: Dynamic) {
        dhke_encrypt(remote_id, socket, info, recv_msg, function(err: Dynamic) {err_msg("connection", remote_id, err);});
        //store connection data
        if (info.client) {
            if (peers[remote_id].cli != null) {
                peers[remote_id].cli.destroy();
            }
            peers[remote_id].cli = socket;
        } else {
            if (peers[remote_id].srv != null) {
                peers[remote_id].srv.destroy();
            }
            peers[remote_id].srv = socket;
        }
        //remove timeout if exists (reconnection after losing connection)
        if (peers[remote_id].timeout != null) {
            rst_conn(remote_id);
            stop_timeout(remote_id);
        }
    }

    private function peer_disconnect(remote_id: Dynamic, socket: Dynamic, info: Dynamic) {
        //remove whatever disconnected
        if (info.client) {
            if (peers[remote_id].cli == socket) {
                peers[remote_id].cli = null;
                peers[remote_id].cenc = null;
            }
        } else {
            if (peers[remote_id].srv == socket) {
                peers[remote_id].srv = null;
                peers[remote_id].senc = null;
            }
        }

        //timeout code
        if (peers[remote_id].srv == null && peers[remote_id].cli == null) {
            lst_conn(remote_id);
            start_timeout(remote_id);
        }
    }

    private function start_timeout(remote_id: Dynamic) {
        //ensures another timer isn't already running
        stop_timeout(remote_id);

        //start timeout
        peers[remote_id].timeout = new haxe.Timer(timeout);
        peers[remote_id].timeout.run = function() {
            timeout_conn(remote_id);
        }
    }

    private function stop_timeout(remote_id: Dynamic) {
        //ensure timer exists
        if (peers[remote_id].timeout != null) {
            peers[remote_id].timeout.stop();
            peers[remote_id].timeout = null;
        }
    }

    private function timeout_conn(remote_id: Dynamic) {
        //cleanup
        tim_conn(remote_id);
        peers[remote_id].timeout.stop();
        peers[remote_id].timeout = null;
        peers[remote_id].sw.destroy();
        peers[remote_id].sw = null;
        peers.remove(remote_id);
    }

    static public function encrypt(data: String, aes: haxe.crypto.Aes): String {
        return aes.encrypt(haxe.crypto.mode.Mode.CTR, haxe.io.Bytes.ofString(data), haxe.crypto.padding.Padding.NoPadding).toHex();
    }

    static public function decrypt(data: String, aes: haxe.crypto.Aes): String {
        return aes.decrypt(haxe.crypto.mode.Mode.CTR, haxe.io.Bytes.ofHex(data), haxe.crypto.padding.Padding.NoPadding).toString();
    }
 }
