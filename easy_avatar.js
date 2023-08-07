var deletables=[]
BBPlugin.register('easy_avatar', {
	title: 'Easy Avatar',
	author: '4P5',
	icon: 'icon',
	description: 'Create toggleable accessories, animations, and more without scripting!',
	version: '1.0.0',
	variant: 'both',
	onload() {
		/**
		 * @type {{[formElement: string]: "_" | DialogFormElement}}
		 */
		
		deletables.push(new Property(Group, 'string', 'accessory_name'));
		deletables.push(new Property(Group, 'string', 'accessory_item'));
		button=new Action('accessory', {
			name: 'Figura Accessory Properties',
			icon: 'extension',
			click: function () {
				const form = {
					accessory_name: { label: 'Name', type: 'string', value: Group.selected.accessory_name, description: 'The name of the accessory. If two accessories share a name, they will be grouped together and treated as one.', required: true },
					accessory_item: { label: 'Item', type: 'string', value: Group.selected.accessory_item, description: 'The ID of the item that will be used for the accessory. Can be blank.'},
				}
				new Dialog({
					title: 'Accessory Properties',
					id: 'accessories',
					form,
					lines: [
						'Fill out a name to create a new accessory. The accessory will show up in your action wheel, and can be toggled on and off.',
					],
					data: {
						accessory_name: Group.selected.accessory_name,
						accessory_item: Group.selected.accessory_item,
					},
					onConfirm: (data) => {
						for (const key in data) {
							Group.selected[key] = data[key]
						}
						if (Group.selected.accessory_name != '') {
							Blockbench.showQuickMessage("Accessory updated!", 2000)
						} else {
							Blockbench.showQuickMessage("Accessory removed!", 2000)
						}
							
					},
				}).show()
			},
			condition: { modes: ['edit'], method: () => Group.selected instanceof Group },
		})
		deletables.push(button)
		Cube.prototype.menu.addAction(button);
		Group.prototype.menu.addAction(button);
	},
	onunload(){
		deletables.forEach((deletable)=>deletable.delete())
	}
})