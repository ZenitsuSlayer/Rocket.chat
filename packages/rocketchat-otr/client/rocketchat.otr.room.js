RocketChat.OTR.Room = class {
	constructor(userId, roomId) {
		this.userId = userId;
		this.roomId = roomId;
		this.peerId = roomId.replace(userId, '');
		this.established = new ReactiveVar(false);
		this.establishing = new ReactiveVar(false);
		this.publicKeyJWK = null;
		this.publicKey = null;
		this.privateKey = null;
		this.peerPublicKey = null;
	}

	handshake() {
		this.establishing.set(true);
		this.established.set(false);
		this.getPublicAndPrivateKeys(false, () => {
			RocketChat.Notifications.notifyUser(this.peerId, 'otr', 'handshake', { roomId: this.roomId, userId: this.userId, publicKey: this.publicKeyJWK });
		});
	}

	acknowledge() {
		this.establishing.set(false);
		this.established.set(true);
		this.getPublicAndPrivateKeys(false, () => {
			RocketChat.Notifications.notifyUser(this.peerId, 'otr', 'acknowledge', { roomId: this.roomId, userId: this.userId, publicKey: this.publicKeyJWK });
		});
	}

	deny() {
		this.establishing.set(false);
		this.established.set(false);
		RocketChat.Notifications.notifyUser(this.peerId, 'otr', 'deny', { roomId: this.roomId, userId: this.userId });
	}

	end() {
		this.establishing.set(false);
		this.established.set(false);
		RocketChat.Notifications.notifyUser(this.peerId, 'otr', 'end', { roomId: this.roomId, userId: this.userId });
	}

	bytesToHexString(bytes) {
		if (!bytes)
			return null;
		bytes = new Uint8Array(bytes);
		var hexBytes = [];
		for (var i = 0; i < bytes.length; ++i) {
			var byteString = bytes[i].toString(16);
			if (byteString.length < 2)
				byteString = "0" + byteString;
			hexBytes.push(byteString);
		}
		return hexBytes.join("");
	}

	hexStringToUint8Array(hexString) {
		if (hexString.length % 2 != 0)
			throw "Invalid hexString";
		var arrayBuffer = new Uint8Array(hexString.length / 2);
		for (var i = 0; i < hexString.length; i += 2) {
			var byteValue = parseInt(hexString.substr(i, 2), 16);
			if (byteValue == NaN)
				throw "Invalid hexString";
			arrayBuffer[i/2] = byteValue;
		}
		return arrayBuffer;
	}

	getPublicAndPrivateKeys(refreshKeys, callback) {
		if (!this.privateKey || !this.publicKey || refreshKeys) {
			// Generate private and public keys
			window.crypto.subtle.generateKey({
					name: "RSA-OAEP",
					modulusLength: 2048, //can be 1024, 2048, or 4096
					publicExponent: new Uint8Array([0x01, 0x00, 0x01]),
					hash: {name: "SHA-256"}, //can be "SHA-1", "SHA-256", "SHA-384", or "SHA-512"
				},
				true, //whether the key is extractable (i.e. can be used in exportKey)
				["encrypt", "decrypt"] //must be ["encrypt", "decrypt"] or ["wrapKey", "unwrapKey"]
			)
			.then((key) => {
				// export private key
				this.privateKey = key.privateKey;
				this.publicKey = key.publicKey;
				// export public key
				window.crypto.subtle.exportKey(
					"jwk", //can be "jwk" (public or private), "spki" (public only), or "pkcs8" (private only)
					key.publicKey //can be a publicKey or privateKey, as long as extractable was true
				)
				.then((publicKey) => {
					this.publicKeyJWK = publicKey;
				})
				.then(() => {
					if (callback) {
						callback();
					}
				})
			})
			.catch((err) => {
				console.error(err);
			});
		} else {
			if (callback) {
				callback();
			}
		}
	}

	importPublicKey(publicKey) {
		return window.crypto.subtle.importKey(
			"jwk", //can be "jwk" (public or private), "spki" (public only), or "pkcs8" (private only)
			publicKey,
			{   //these are the algorithm options
				name: "RSA-OAEP",
				hash: {name: "SHA-256"}, //can be "SHA-1", "SHA-256", "SHA-384", or "SHA-512"
			},
			true, //whether the key is extractable (i.e. can be used in exportKey)
			["encrypt"] //"encrypt" or "wrapKey" for public key import or
		)
	}

	onUserStream(type, data) {
		const user = Meteor.users.findOne(data.userId);
		switch(type) {
			case 'handshake':
				let timeout = null;
				this.establishing.set(true);
				swal({
					title: "<i class='icon-key alert-icon'></i>" + TAPi18n.__("OTR"),
					text: TAPi18n.__("Username_wants_to_start_otr_Do_you_want_to_accept", { username: user.username }),
					html: true,
					showCancelButton: true,
					confirmButtonText: TAPi18n.__("Yes"),
					cancelButtonText: TAPi18n.__("No")
				}, (isConfirm) => {
					if (isConfirm) {
						Meteor.clearTimeout(timeout);
						this.importPublicKey(data.publicKey).then((publicKey) => {
							this.peerPublicKey = publicKey;
							FlowRouter.goToRoomById(data.roomId);
							Meteor.defer(() => {
								this.acknowledge();
							});
						});
					} else {
						Meteor.clearTimeout(timeout);
						this.deny();
					}
				});
				timeout = Meteor.setTimeout(() => {
					this.establishing.set(false);
					swal.close();
				}, 10000);
				break;
			case 'acknowledge':
				this.importPublicKey(data.publicKey).then((publicKey) => {
					this.peerPublicKey = publicKey;
					this.establishing.set(false);
					this.established.set(true);
				});
				break;
			case 'deny':
				this.establishing.set(false);
				this.established.set(false);
				swal(TAPi18n.__("Denied"), null, "error");
				break;
			case 'end':
				this.establishing.set(false);
				this.established.set(false);
				swal(TAPi18n.__("Ended"), null, "error");
				break;
		}
	}

	encrypt(message) {
		const textMsg = message.msg;
		// Encrypt with peer's public key
		return window.crypto.subtle.encrypt({
				name: "RSA-OAEP",
			},
			this.peerPublicKey,
			new TextEncoder("UTF-8").encode(textMsg) //ArrayBuffer of data you want to encrypt
		)
		.then((encrypted) => {
			message.msg = this.bytesToHexString(encrypted);
			message.otr = true;
			return window.crypto.subtle.encrypt({
					name: "RSA-OAEP",
				},
				this.publicKey,
				new TextEncoder("UTF-8").encode(textMsg) //ArrayBuffer of data you want to encrypt
			).then((encrypted) => {
				message.ownMsg = this.bytesToHexString(encrypted);
				return message;
			})
		})
		.catch(function(err){
			return message;
		});
	}

	decrypt(message) {
		return window.crypto.subtle.decrypt({
				name: "RSA-OAEP",
			},
			this.privateKey,
			new this.hexStringToUint8Array(message.u._id === Meteor.userId() ? message.ownMsg : message.msg) //ArrayBuffer of the data
		)
		.then((decrypted) => {
			//returns an ArrayBuffer containing the decrypted data
			message.msg = new TextDecoder("UTF-8").decode(new Uint8Array(decrypted));
			return message;
		})
		.catch(function(err){
			return message;
		});
	}
}
