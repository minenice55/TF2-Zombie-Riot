
void OnTakeDamage_HandOfElderMages(int client, int holding_weapon)
{
	if(b_HandOfElderMages)
	{
		if(i_IsWandWeapon[holding_weapon])
		{
			Saga_ChargeReduction(client, holding_weapon, 2.0);
		}	
	}
}

public void Rogue_Item_HandOfElderMages()
{
	b_HandOfElderMages = true;
}
public void Rogue_Item_HandOfElderMagesRemoved()
{
	b_HandOfElderMages = false;
}