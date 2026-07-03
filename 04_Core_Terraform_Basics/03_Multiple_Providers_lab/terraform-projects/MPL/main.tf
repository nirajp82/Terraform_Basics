resource "random_pet" "my_pet"{
    length = 2
    separator = "-"
    prefix = "Dog"
}

resource "local_file" "my_pet" {
    filename = "root/${random_pet.my_pet.id}.txt"
    content = "My pet is called ${random_pet.my_pet.id}."
}